//
//  CSVImporterTests.swift
//  ETPatternTests
//
//  Created by admin on 28/11/2025.
//

import XCTest
import CoreData
@testable import ETPattern

class CSVImporterTests: XCTestCase {

    var persistenceController: PersistenceController!
    var csvImporter: CSVImporter!

    override func setUp() {
        super.setUp()
        persistenceController = PersistenceController(inMemory: true)
        csvImporter = CSVImporter(viewContext: persistenceController.container.viewContext)
    }

    override func tearDown() {
        csvImporter = nil
        persistenceController = nil
        super.tearDown()
    }

    func testParseCSVWithValidData() {
        let csvContent = """
Front;;Back;;Tags
I think...;;Example 1<br>Example 2<br>Example 3<br>Example 4<br>Example 5;;1-Group1
You know...;;Example A<br>Example B<br>Example C<br>Example D<br>Example E;;2-Group2
"""

        let cards = csvImporter.parseCSV(csvContent, cardSetName: "TestSet")

        XCTAssertEqual(cards.count, 2, "Should parse 2 cards from valid CSV")

        let firstCard = cards[0]
        XCTAssertEqual(firstCard.front, "I think...")
        XCTAssertEqual(firstCard.back, "Example 1\nExample 2\nExample 3\nExample 4\nExample 5")
        XCTAssertEqual(firstCard.tags, "1-Group1")
        XCTAssertEqual(firstCard.groupId, 1)
        XCTAssertEqual(firstCard.groupName, "Group1")

        let secondCard = cards[1]
        XCTAssertEqual(secondCard.front, "You know...")
        XCTAssertEqual(secondCard.back, "Example A\nExample B\nExample C\nExample D\nExample E")
        XCTAssertEqual(secondCard.tags, "2-Group2")
        XCTAssertEqual(secondCard.groupId, 2)
        XCTAssertEqual(secondCard.groupName, "Group2")
    }

    func testParseCSVWithInvalidData() {
        let csvContent = """
Front;;Back;;Tags
;;Invalid Card;;
Valid Front;;Valid Back;;
"""

        let cards = csvImporter.parseCSV(csvContent, cardSetName: "TestSet")

        XCTAssertEqual(cards.count, 1, "Should skip invalid cards")
        XCTAssertEqual(cards[0].front, "Valid Front")
        XCTAssertEqual(cards[0].back, "Valid Back")
    }

    func testParseCSVWithEmptyTags() {
        let csvContent = """
Front;;Back;;Tags
Pattern;;Examples;;
"""

        let cards = csvImporter.parseCSV(csvContent, cardSetName: "TestSet")

        XCTAssertEqual(cards.count, 1)
        XCTAssertEqual(cards[0].tags, "")
        XCTAssertEqual(cards[0].groupId, 0)
        XCTAssertEqual(cards[0].groupName, "")
    }

    func testParseCSVWithMalformedTags() {
        let csvContent = """
Front;;Back;;Tags
Pattern;;Examples;;NoNumber-Tag
"""

        let cards = csvImporter.parseCSV(csvContent, cardSetName: "TestSet")

        XCTAssertEqual(cards.count, 1)
        XCTAssertEqual(cards[0].tags, "NoNumber-Tag")
        XCTAssertEqual(cards[0].groupId, 0)
        XCTAssertEqual(cards[0].groupName, "NoNumber-Tag")
    }
}