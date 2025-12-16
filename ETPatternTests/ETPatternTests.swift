//
//  ETPatternTests.swift
//  ETPatternTests
//
//  Created by admin on 25/11/2025.
//

import XCTest
import CoreData
@testable import ETPattern

final class ETPatternTests: XCTestCase {

    var persistenceController: PersistenceController!

    override func setUp() {
        super.setUp()
        persistenceController = PersistenceController(inMemory: true)
    }

    override func tearDown() {
        persistenceController = nil
        super.tearDown()
    }

    @MainActor
    func testPreviewControllerSeedsSampleCards() throws {
        let context = PersistenceController.preview.container.viewContext
        let request: NSFetchRequest<Card> = Card.fetchRequest()
        let cards = try context.fetch(request)
        XCTAssertEqual(cards.count, 5, "Preview controller should create five sample cards for SwiftUI previews")
    }
}