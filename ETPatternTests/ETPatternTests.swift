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

    @MainActor
    func testPreviewControllerSeedsSampleCards() throws {
        let context = PersistenceController.preview.container.viewContext
        let request: NSFetchRequest<Card> = Card.fetchRequest()
        let cards = try context.fetch(request)
        XCTAssertEqual(cards.count, 5, "Preview controller should create five sample cards for SwiftUI previews")
    }
}
