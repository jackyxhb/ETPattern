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
}