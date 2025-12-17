//
//  Persistence.swift
//  ETPattern
//
//  Created by admin on 25/11/2025.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

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
            card.front = "Sample pattern \(i)"
            card.back = "Example 1<br>Example 2<br>Example 3<br>Example 4<br>Example 5"
            card.tags = "sample"
            card.difficulty = 0
            card.nextReviewDate = Date()
            card.interval = 1
            card.easeFactor = 2.5
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
        container = NSPersistentContainer(name: "ETPattern")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
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
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    func initializeBundledCardSets() {
        let viewContext = container.viewContext

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
