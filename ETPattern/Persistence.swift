//
//  Persistence.swift
//  ETPattern
//
//  Created by admin on 25/11/2025.
//

import Foundation
import SwiftData
import ETPatternModels
import ETPatternServices
import ETPatternCore

@MainActor
struct PersistenceController {
    static let shared = PersistenceController()

    static let preview: PersistenceController = {
        let schema = Schema([Card.self, CardSet.self, StudySession.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        let result = PersistenceController(container: container)
        
        let context = container.mainContext
        
        // Create sample CardSet
        let cardSet = CardSet(name: "Sample Group")
        context.insert(cardSet)

        // Create sample cards
        for i in 1...5 {
            let card = Card(
                id: Int32(i),
                front: "Sample pattern \(i)",
                back: "Example 1\nExample 2\nExample 3\nExample 4\nExample 5",
                cardName: "Sample pattern \(i)",
                groupId: 0,
                groupName: ""
            )
            card.tags = "sample"
            card.cardSet = cardSet
            cardSet.cards.append(card)
            context.insert(card)
        }

        try? context.save()
        return result
    }()

    let container: ModelContainer

    init(inMemory: Bool = false) {
        let schema = Schema([Card.self, CardSet.self, StudySession.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            self.container = container
            
            // Seed bundled decks after container is ready
            Task {
                await PersistenceController.seedBundledCardSets(modelContext: container.mainContext)
            }
        } catch {
            fatalError("Could not configure SwiftData container: \(error)")
        }
    }
    
    // Explicit init for preview or specific cases
    init(container: ModelContainer) {
        self.container = container
    }

    func initializeBundledCardSets() {
        Task {
            await Self.seedBundledCardSets(modelContext: container.mainContext)
        }
    }

    private static func seedBundledCardSets(modelContext: ModelContext) async {
        let csvImporter = CSVImporter(modelContext: modelContext)
        let bundledFiles = FileManagerService.getBundledCSVFiles()
        let masterDeckName = Constants.Decks.bundledMasterName

        // Check if master deck already exists
        let masterDeckFetch = FetchDescriptor<CardSet>(predicate: #Predicate { $0.name == masterDeckName })
        let existingMasterDecks = (try? modelContext.fetch(masterDeckFetch)) ?? []
        let masterDeck: CardSet
        
        if let existing = existingMasterDecks.first {
            masterDeck = existing
        } else {
            masterDeck = CardSet(name: masterDeckName)
            modelContext.insert(masterDeck)
        }

        if !masterDeck.cards.isEmpty {
            // Master deck already exists and is populated. Check if any cards have nil id and assign IDs.
            let cardsWithNilId = masterDeck.cards.filter { $0.id == 0 }
            if !cardsWithNilId.isEmpty {
                var nextId: Int32 = 1
                // Find the highest existing card ID to avoid conflicts
                var fetchDescriptor = FetchDescriptor<Card>(sortBy: [SortDescriptor(\.id, order: .reverse)])
                fetchDescriptor.fetchLimit = 1
                if let highestIdCard = (try? modelContext.fetch(fetchDescriptor))?.first {
                    nextId = highestIdCard.id + 1
                }
                for card in cardsWithNilId {
                    card.id = nextId
                    nextId += 1
                }
                try? modelContext.save()
            }
            return
        }

        var totalImported = 0
        var importErrors: [String] = []
        var nextCardId: Int32 = 1

        // Find the highest existing card ID
        var fetchDescriptor = FetchDescriptor<Card>(sortBy: [SortDescriptor(\.id, order: .reverse)])
        fetchDescriptor.fetchLimit = 1
        if let highestIdCard = (try? modelContext.fetch(fetchDescriptor))?.first {
            nextCardId = highestIdCard.id + 1
        }

        for fileName in bundledFiles {
            if let content = FileManagerService.loadBundledCSV(named: fileName) {
                let cards = csvImporter.parseCSV(content, cardSetName: masterDeckName)

                for card in cards {
                    card.id = nextCardId
                    nextCardId += 1
                    card.cardSet = masterDeck
                    masterDeck.cards.append(card)
                    modelContext.insert(card)
                }
                totalImported += cards.count
            } else {
                importErrors.append("Failed to load bundled CSV \(fileName)")
            }
        }

        do {
            if totalImported > 0 {
                try modelContext.save()
            }
        } catch {
            importErrors.append("Failed to save bundled card sets: \(error.localizedDescription)")
        }

        if !importErrors.isEmpty {
            UserDefaults.standard.set(importErrors, forKey: "bundledImportErrors")
        }
    }
}

