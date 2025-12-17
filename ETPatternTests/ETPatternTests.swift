//
//  ETPatternTests.swift
//  ETPatternTests
//
//  Created by admin on 25/11/2025.
//

import CoreData
import Testing
@testable import ETPattern

@Suite("App")
struct ETPatternTests {

    @MainActor
    @Test
    func previewControllerSeedsSampleCards() throws {
        let context = PersistenceController.preview.container.viewContext
        let request: NSFetchRequest<Card> = Card.fetchRequest()
        let cards = try context.fetch(request)
        #expect(cards.count == 5)
    }
}
