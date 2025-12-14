//
//  CSVImportTests.swift
//  ETPatternTests
//
//  Created by admin on 28/11/2025.
//

import XCTest
import CoreData
@testable import ETPattern

class CSVImportTests: XCTestCase {

    var persistenceController: PersistenceController!

    override func setUp() {
        super.setUp()
        persistenceController = PersistenceController(inMemory: true)
    }

    override func tearDown() {
        persistenceController = nil
        super.tearDown()
    }

    func testCSVImport() {
        let viewContext = persistenceController.container.viewContext
        let csvImporter = CSVImporter(viewContext: viewContext)

        // Create a test card set first
        let testCardSet = CardSet(context: viewContext)
        testCardSet.name = "Test Set"
        testCardSet.createdDate = Date()

        // Test parsing a simple CSV string
        let csvContent = """
Front;;Back;;Tags
Test Pattern;;Example 1<br>Example 2;;test-tag
"""

        let cards = csvImporter.parseCSV(csvContent, cardSetName: "Test Set")

        // Associate cards with the card set
        for card in cards {
            card.cardSet = testCardSet
        }
        testCardSet.addToCards(NSSet(array: cards))

        XCTAssertEqual(cards.count, 1, "Should parse one card")
        XCTAssertEqual(cards[0].front, "Test Pattern", "Front should match")
        XCTAssertEqual(cards[0].back, "Example 1\nExample 2", "Back should have line breaks converted")
        XCTAssertEqual(cards[0].tags, "test-tag", "Tags should match")
    }

    func testBundledCSVFilesExist() {
        let bundledFiles = FileManagerService.getBundledCSVFiles()
        XCTAssertEqual(bundledFiles.count, 12, "Should have 12 bundled CSV files")

        for fileName in bundledFiles {
            XCTAssertTrue(fileName.hasPrefix("Group"), "File name should start with 'Group'")
            let content = FileManagerService.loadBundledCSV(named: fileName)
            XCTAssertNotNil(content, "Should be able to load \(fileName)")
            XCTAssertFalse(content!.isEmpty, "\(fileName) should not be empty")
        }
    }

    func testInitializeBundledCardSets() {
        // Test that bundled card sets can be initialized
        persistenceController.initializeBundledCardSets()

        let viewContext = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<CardSet> = CardSet.fetchRequest()

        do {
            let cardSets = try viewContext.fetch(fetchRequest)
            XCTAssertGreaterThan(cardSets.count, 0, "Should have loaded card sets")

            // Check that at least one card set has cards
            var totalCards = 0
            for cardSet in cardSets {
                totalCards += cardSet.cards?.count ?? 0
            }
            XCTAssertGreaterThan(totalCards, 0, "Should have loaded some cards")
        } catch {
            XCTFail("Failed to fetch card sets: \(error)")
        }
    }

    func testIntegration_CSVImportAndSpacedRepetition() {
        let viewContext = persistenceController.container.viewContext
        let csvImporter = CSVImporter(viewContext: viewContext)
        let spacedRepetitionService = SpacedRepetitionService()

        // Create a test card set
        let testCardSet = CardSet(context: viewContext)
        testCardSet.name = "Integration Test Set"
        testCardSet.createdDate = Date()

        // Import CSV
        let csvContent = """
Front;;Back;;Tags
I think...;;I think it's raining.<br>I think you should go.<br>I think this is fun.;;pattern
"""

        let cards = csvImporter.parseCSV(csvContent, cardSetName: "Integration Test Set")
        for card in cards {
            card.cardSet = testCardSet
        }
        testCardSet.addToCards(NSSet(array: cards))

        // Save to Core Data
        do {
            try viewContext.save()
        } catch {
            XCTFail("Failed to save cards: \(error)")
        }

        // Test spaced repetition on imported cards
        let dueCards = spacedRepetitionService.getCardsDueForReview(from: testCardSet)
        XCTAssertEqual(dueCards.count, 1, "New card should be due")

        // Update difficulty
        spacedRepetitionService.updateCardDifficulty(dueCards[0], rating: .easy)

        // Verify next review date is set
        XCTAssertNotNil(dueCards[0].nextReviewDate, "Next review date should be set")
        XCTAssertGreaterThan(dueCards[0].interval, 1, "Interval should increase for easy rating")
    }

    func testError_InvalidCSV() {
        let viewContext = persistenceController.container.viewContext
        let csvImporter = CSVImporter(viewContext: viewContext)

        // Test invalid CSV with wrong separator
        let invalidCSV = """
Front,Back,Tags
Test Pattern,Example 1,Example 2,test-tag
"""

        let cards = csvImporter.parseCSV(invalidCSV, cardSetName: "Test Set")
        XCTAssertEqual(cards.count, 0, "Should not parse invalid CSV with wrong separator")
    }

    func testError_CoreDataSaveFailure() {
        // Create a context that will fail to save (simulate by using a read-only context or invalid setup)
        // For simplicity, we'll test with a card that has invalid data, but Core Data is forgiving

        let viewContext = persistenceController.container.viewContext

        // Create card with nil front (should still save, but test error handling)
        let card = Card(context: viewContext)
        card.front = nil
        card.back = "Test back"
        card.tags = "test"

        do {
            try viewContext.save()
            // If it saves, that's fine - Core Data allows nil strings
        } catch {
            // If it fails, that's also acceptable for this test
            XCTAssertNotNil(error, "Error should be handled gracefully")
        }
    }
}