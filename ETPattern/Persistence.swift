//
//  Persistence.swift
//  ETPattern
//
//  Created by admin on 25/11/2025.
//

import Foundation
import SwiftData
import CloudKit
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
        let schema = Schema([Card.self, CardSet.self, StudySession.self, ReviewLog.self])
        let config: ModelConfiguration
        
        if inMemory {
            config = ModelConfiguration(isStoredInMemoryOnly: true)
        } else {
            // Attempt CloudKit configuration
            let ckConfig = ModelConfiguration(
                schema: schema,
                cloudKitDatabase: .private("iCloud.com.jackxhb.ETPattern")
            )
            
            // Validate if we can use this config (basic check)
            config = ckConfig
        }

        do {
            print("🚀 Persistence: Initializing ModelContainer...")
            let container = try ModelContainer(for: schema, configurations: [config])
            self.container = container
            print("✅ Persistence: ModelContainer initialized successfully.")
            
            // Seed bundled decks after container is ready
            
            // Seed bundled decks logic is now handled by AppInitManager
            print("✅ Persistence: ModelContainer initialized. Waiting for AppInitManager.")
        } catch {
            print("❌ Persistence: Failed to initialize with CloudKit: \(error.localizedDescription)")
            print("🔄 Persistence: Falling back to local storage...")
            
            do {
                let localConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
                let container = try ModelContainer(for: schema, configurations: [localConfig])
                self.container = container
                print("✅ Persistence: Fallback ModelContainer initialized.")
            } catch {
                print("🛑 Persistence: CRITICAL ERROR - Fallback failed: \(error)")
                fatalError("Could not configure SwiftData container: \(error)")
            }
        }
    }
    
    // Explicit init for preview or specific cases
    init(container: ModelContainer) {
        self.container = container
    }

    @MainActor
    func initializeBundledCardSets(force: Bool = false) async -> String {
        return await Self.seedBundledCardSets(modelContext: container.mainContext, force: force)
    }

    @MainActor
    private static func seedBundledCardSets(modelContext: ModelContext, force: Bool) async -> String {
        let csvImporter = CSVImporter(modelContext: modelContext)
        let bundledFiles = FileManagerService.getBundledCSVFiles().sorted {
            $0.localizedStandardCompare($1) == .orderedAscending
        }
        let masterDeckName = Constants.Decks.bundledMasterName

        // Fetch existing decks
        let masterDeckFetch = FetchDescriptor<CardSet>(predicate: #Predicate { $0.name == masterDeckName })
        let existingMasterDecks = (try? modelContext.fetch(masterDeckFetch)) ?? []
        
        let masterDeck: CardSet

        if force {
            print("🧨 Persistence: FORCE RESET triggered. Deleting \(existingMasterDecks.count) existing master decks...")
            for deck in existingMasterDecks {
                modelContext.delete(deck)
            }
            try? modelContext.save() // Commit deletion
            
            // Create fresh deck
            masterDeck = CardSet(name: masterDeckName)
            modelContext.insert(masterDeck)
        } else {
             // Normal logic (resume or skip)
             if let existing = existingMasterDecks.first {
                 masterDeck = existing
                 let currentCount = masterDeck.cards.count
                 
                 // If count is suspiciously high (e.g. double import of 299 cards = 598), force reset
                 if currentCount > 400 {
                     print("⚠️ Persistence: Detected potential duplicate data (\(currentCount) cards). Triggering AUTO-REPAIR.")
                     // Recursively call with force=true to wipe and re-seed
                     return await seedBundledCardSets(modelContext: modelContext, force: true)
                 }
                 
                 if currentCount >= 290 { // Lower threshold slightly to avoid loops if count is persistent
                     return "Skipped: Master deck already has \(currentCount) cards."
                 }
             } else {
                 masterDeck = CardSet(name: masterDeckName)
                 modelContext.insert(masterDeck)
             }
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
                importErrors.append("Scale: \(fileName) -> \(cards.count) cards") 
            } else {
                importErrors.append("Failed: \(fileName)")
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
        if !importErrors.isEmpty {
            UserDefaults.standard.set(importErrors, forKey: "bundledImportErrors")
            return "Completed with errors: \(importErrors.count) files failed. Imported: \(totalImported)"
        }
        
        return "Success: Imported \(totalImported) cards from \(bundledFiles.count) files."
    }
}

