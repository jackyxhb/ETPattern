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

        // Check if card sets are already initialized
        let fetchRequest: NSFetchRequest<CardSet> = CardSet.fetchRequest()
        do {
            let existingSets = try viewContext.fetch(fetchRequest)
            if !existingSets.isEmpty {
                return // Already initialized
            }
        } catch {
            print("Error checking existing card sets: \(error)")
        }

        // Initialize bundled card sets
        let csvImporter = CSVImporter(viewContext: viewContext)
        let bundledFiles = FileManagerService.getBundledCSVFiles()

        for fileName in bundledFiles {
            let cardSetName = FileManagerService.getCardSetName(from: fileName)
            csvImporter.importBundledCSV(named: fileName, cardSetName: cardSetName)
        }

        do {
            try viewContext.save()
        } catch {
            print("Error saving initialized card sets: \(error)")
        }
    }
}
