//
//  Persistence.swift
//  ETPattern
//
//  Created by admin on 25/11/2025.
//

import Foundation
import CoreData

class PersistenceController {
    static let shared = PersistenceController()

    private final class ModelBundleToken {}

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        // Create sample CardSet
        let cardSet = CardSet(context: viewContext)
        cardSet.name = "Sample Group"
        cardSet.createdDate = Date()

        // Create sample cards
        for i in 1...5 {
            let card = Card(context: viewContext)
            card.id = Int32(i)
            card.front = "Sample pattern \(i)"
            card.back = "Example 1<br>Example 2<br>Example 3<br>Example 4<br>Example 5"
            card.tags = "sample"
            card.cardName = card.front ?? "Sample pattern \(i)"
            card.groupId = 1
            card.groupName = cardSet.name ?? "Sample Group"
            card.difficulty = 0
            card.nextReviewDate = Date()
            card.interval = Constants.SpacedRepetition.initialInterval
            card.easeFactor = Constants.SpacedRepetition.defaultEaseFactor
            card.cardSet = cardSet
        }

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer
    private var isStoreLoaded = false

    init(inMemory: Bool = false) {
        let modelName = "ETPattern"

        let modelURL = Bundle(for: ModelBundleToken.self).url(forResource: modelName, withExtension: "momd")
            ?? Bundle.main.url(forResource: modelName, withExtension: "momd")

        guard let modelURL, let loadedModel = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Unable to locate Core Data model \(modelName).momd in bundle")
        }

        // Create a mutable copy of the model to allow binding managed object classes
        let model = loadedModel.copy() as! NSManagedObjectModel

        // Defensive: ensure entities resolve to the intended Swift subclasses.
        // This prevents crashes like: "Expected CardSet but found NSManagedObject".
        PersistenceController.bindManagedObjectClasses(to: model)

        container = NSPersistentContainer(name: modelName, managedObjectModel: model)

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            description.url = URL(fileURLWithPath: "/dev/null")
            container.persistentStoreDescriptions = [description]
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            self.isStoreLoaded = true
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    private static func bindManagedObjectClasses(to model: NSManagedObjectModel) {
        let mapping: [String: NSManagedObject.Type] = [
            "CardSet": CardSet.self,
            "Card": Card.self,
            "StudySession": StudySession.self,
        ]

        for (entityName, cls) in mapping {
            guard let entity = model.entitiesByName[entityName] else { continue }
            entity.managedObjectClassName = NSStringFromClass(cls)
        }
    }

    func initializeBundledCardSets() {
        let viewContext = container.viewContext

        print("DEBUG: Ensuring bundled card sets are initialized...")
        let csvImporter = CSVImporter(viewContext: viewContext)
        let bundledFiles = FileManagerService.getBundledCSVFiles()
        let masterDeckName = Constants.Decks.bundledMasterName

        // Fetch or create the single master deck that will hold all bundled cards
        let fetchRequest: NSFetchRequest<CardSet> = CardSet.fetchRequest()
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "name == %@", masterDeckName)

        let masterDeck: CardSet
        if let existingDeck = (try? viewContext.fetch(fetchRequest))?.first {
            // Check if the deck already has cards - if so, skip re-import for performance
            if let existingCards = existingDeck.cards as? Set<Card>, !existingCards.isEmpty {
                print("DEBUG: Master deck '\(masterDeckName)' already has \(existingCards.count) cards, skipping re-import")
                return
            }
            // Deck exists but has no cards, so we'll re-import
            masterDeck = existingDeck
        } else {
            masterDeck = CardSet(context: viewContext)
            masterDeck.name = masterDeckName
            masterDeck.createdDate = Date()
        }

        var totalImported = 0
        var importErrors: [String] = []

        for fileName in bundledFiles {
            do {
                let cardSet = try csvImporter.importBundledCSV(named: fileName, cardSetName: masterDeckName)
                if let cards = cardSet.cards {
                    let cardCount = cards.count
                    totalImported += Int(cardCount)
                    print("DEBUG: Imported \(cardCount) cards from \(fileName) into '\(masterDeckName)'")
                }
            } catch {
                let errorMessage = "Failed to import \(fileName): \(error.localizedDescription)"
                importErrors.append(errorMessage)
                print("ERROR: \(errorMessage)")
            }
        }

        do {
            if totalImported > 0 && viewContext.hasChanges {
                try viewContext.save()
                print("DEBUG: Saved \(totalImported) bundled cards to deck '\(masterDeckName)'")
            } else {
                print("DEBUG: No bundled cards imported; nothing to save")
            }
        } catch {
            let errorMessage = "Failed to save bundled card sets: \(error.localizedDescription)"
            importErrors.append(errorMessage)
            print("ERROR: \(errorMessage)")
        }

        // Store any import errors for potential user notification
        if !importErrors.isEmpty {
            UserDefaults.standard.set(importErrors, forKey: "bundledImportErrors")
        }
    }

    /// UI-test-only: seed a tiny, deterministic dataset so the app launches quickly.
    /// The full bundled import is intentionally skipped when `UITESTING` launch arg is present.
    func initializeUITestSeedData() {
        while !isStoreLoaded {
            usleep(10000)
        }
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        let viewContext = container.viewContext
        let masterDeckName = Constants.Decks.bundledMasterName

        let fetchRequest: NSFetchRequest<CardSet> = CardSet.fetchRequest()
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "name == %@", masterDeckName)

        let deck: CardSet
        if let existingDeck = (try? viewContext.fetch(fetchRequest))?.first {
            deck = existingDeck
        } else {
            let newDeck = CardSet(context: viewContext)
            newDeck.name = masterDeckName
            newDeck.createdDate = Date()
            deck = newDeck
        }

        if let existingCards = deck.cards as? Set<Card>, !existingCards.isEmpty {
            return
        }

        for i in 1...5 {
            let card = Card(context: viewContext)
            card.id = Int32(i)
            card.front = "I think… (UI Test \(i))"
            card.back = "Example 1\nExample 2\nExample 3\nExample 4\nExample 5"
            card.tags = "ui-test"
            card.cardName = card.front ?? "I think… (UI Test \(i))"
            card.groupId = 1
            card.groupName = "UI Test"
            card.difficulty = 0
            card.nextReviewDate = Date()
            card.interval = Constants.SpacedRepetition.initialInterval
            card.easeFactor = Constants.SpacedRepetition.defaultEaseFactor
            card.timesReviewed = 0
            card.timesCorrect = 0
            card.lastReviewedDate = nil
            card.cardSet = deck
        }

        do {
            if viewContext.hasChanges {
                try viewContext.save()
            }
        } catch {
            print("ERROR: Failed to seed UI test data: \(error.localizedDescription)")
        }
    }
}
