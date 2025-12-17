//
//  Persistence.swift
//  ETPattern
//
//  Created by admin on 25/11/2025.
//

import CoreData
import Foundation

struct PersistenceController {
    static let shared = PersistenceController()

    private final class ModelBundleToken: NSObject {}

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        guard let cardSetEntity = NSEntityDescription.entity(forEntityName: "CardSet", in: viewContext),
              let cardEntity = NSEntityDescription.entity(forEntityName: "Card", in: viewContext) else {
            fatalError("Failed to resolve Core Data entities for preview")
        }

        // Create sample CardSet
        let cardSet = CardSet(entity: cardSetEntity, insertInto: viewContext)
        cardSet.name = "Sample Group"
        cardSet.createdDate = Date()

        // Create sample cards
        for i in 1...5 {
            let card = Card(entity: cardEntity, insertInto: viewContext)
            card.id = Int32(i)
            card.front = "Sample pattern \(i)"
            card.cardName = card.front ?? "Sample pattern \(i)"
            card.back = "Example 1<br>Example 2<br>Example 3<br>Example 4<br>Example 5"
            card.tags = "sample"
            card.groupId = 0
            card.groupName = ""
            card.difficulty = 0
            card.nextReviewDate = Date()
            card.interval = 1
            card.easeFactor = 2.5
            card.timesReviewed = 0
            card.timesCorrect = 0
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

    init(inMemory: Bool = false) {
        let modelName = "ETPattern"

        // Explicitly load the model from the ETPattern module bundle to avoid Core Data
        // ambiguity when multiple bundles include a compiled .momd.
        let modelBundle = Bundle(for: ModelBundleToken.self)
        guard let modelURL = modelBundle.url(forResource: modelName, withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Failed to load Core Data model \(modelName).momd from bundle \(modelBundle.bundleURL)")
        }

        container = NSPersistentContainer(name: modelName, managedObjectModel: model)
        let containerRef = container
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }

            // Seed bundled decks only after the persistent store is ready.
            DispatchQueue.main.async {
                PersistenceController.seedBundledCardSets(viewContext: containerRef.viewContext)
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    func initializeBundledCardSets() {
        Self.seedBundledCardSets(viewContext: container.viewContext)
    }

    private static func seedBundledCardSets(viewContext: NSManagedObjectContext) {

        print("DEBUG: Ensuring bundled card sets are initialized...")
        let csvImporter = CSVImporter(viewContext: viewContext)
        let bundledFiles = FileManagerService.getBundledCSVFiles()
        let masterDeckName = Constants.Decks.bundledMasterName

        // Migrate/rename legacy master deck name if it exists.
        let legacyName = Constants.Decks.legacyBundledMasterName
        if legacyName != masterDeckName {
            let legacyFetch: NSFetchRequest<CardSet> = CardSet.fetchRequest()
            legacyFetch.fetchLimit = 1
            legacyFetch.predicate = NSPredicate(format: "name == %@", legacyName)
            if let legacyDeck = (try? viewContext.fetch(legacyFetch))?.first {
                print("DEBUG: Renaming legacy master deck '\(legacyName)' -> '\(masterDeckName)'")
                legacyDeck.name = masterDeckName
                try? viewContext.save()
            }
        }

        func fetchOrCreateCardSet(named name: String) -> CardSet {
            let fetch: NSFetchRequest<CardSet> = CardSet.fetchRequest()
            fetch.fetchLimit = 1
            fetch.predicate = NSPredicate(format: "name == %@", name)
            if let existing = (try? viewContext.fetch(fetch))?.first {
                return existing
            }
            let created = CardSet(context: viewContext)
            created.name = name
            created.createdDate = Date()
            return created
        }

        func cardCount(in set: CardSet) -> Int {
            (set.cards as? Set<Card>)?.count ?? 0
        }

        // 1) Ensure Group 1–12 decks exist (and are populated if empty).
        for bundledFile in bundledFiles {
            let deckDisplayName = FileManagerService.getCardSetName(from: bundledFile)
            let groupDeck = fetchOrCreateCardSet(named: deckDisplayName)

            if cardCount(in: groupDeck) > 0 {
                continue
            }

            guard let content = FileManagerService.loadBundledCSV(named: bundledFile) else {
                print("ERROR: Failed to load bundled CSV \(bundledFile)")
                continue
            }

            let cards = csvImporter.parseCSV(content, cardSetName: deckDisplayName)
            for card in cards {
                card.cardSet = groupDeck
                groupDeck.addToCards(card)
            }
            print("DEBUG: Imported \(cards.count) cards into '\(deckDisplayName)'")
        }

        // 2) Ensure the single master deck exists and is populated if empty.
        let masterDeck = fetchOrCreateCardSet(named: masterDeckName)
        if cardCount(in: masterDeck) > 0 {
            // Master deck already exists; still save any newly created group decks.
            if viewContext.hasChanges {
                try? viewContext.save()
            }
            print("DEBUG: Master deck '\(masterDeckName)' already has \(cardCount(in: masterDeck)) cards, skipping re-import")
            return
        }

        var totalImported = 0
        var importErrors: [String] = []

        for fileName in bundledFiles {
            if let content = FileManagerService.loadBundledCSV(named: fileName) {
                let cards = csvImporter.parseCSV(content, cardSetName: masterDeckName)
                for card in cards {
                    card.cardSet = masterDeck
                    masterDeck.addToCards(card)
                }
                totalImported += cards.count
                print("DEBUG: Imported \(cards.count) cards from \(fileName) into '\(masterDeckName)'")
            } else {
                let errorMessage = "Failed to load bundled CSV \(fileName)"
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
}
