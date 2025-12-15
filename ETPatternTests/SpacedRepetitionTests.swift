//
//  SpacedRepetitionTests.swift
//  ETPatternTests
//
//  Created by admin on 28/11/2025.
//

import XCTest
import CoreData
@testable import ETPattern

class SpacedRepetitionTests: XCTestCase {

    var persistenceController: PersistenceController!
    var spacedRepetitionService: SpacedRepetitionService!

    override func setUp() {
        super.setUp()
        persistenceController = PersistenceController(inMemory: true)
        spacedRepetitionService = SpacedRepetitionService()
    }

    override func tearDown() {
        spacedRepetitionService = nil
        persistenceController = nil
        super.tearDown()
    }

    func testUpdateCardDifficultyAgain() {
        let card = Card(context: persistenceController.container.viewContext)
        card.interval = 5
        card.easeFactor = 2.0

        spacedRepetitionService.updateCardDifficulty(card, rating: .again)

        XCTAssertEqual(card.interval, Constants.SpacedRepetition.againInterval)
        XCTAssertEqual(card.easeFactor, 2.0 - Constants.SpacedRepetition.easeDecrement)
        XCTAssertNotNil(card.nextReviewDate)
    }

    func testUpdateCardDifficultyEasy() {
        let card = Card(context: persistenceController.container.viewContext)
        card.interval = 5
        card.easeFactor = 2.0

        spacedRepetitionService.updateCardDifficulty(card, rating: .easy)

        let expectedInterval = Int32(max(1, Int(5.0 * 2.0 * Constants.SpacedRepetition.easyMultiplier)))
        XCTAssertEqual(card.interval, expectedInterval)
        XCTAssertEqual(card.easeFactor, 2.0 + Constants.SpacedRepetition.easeIncrement)
        XCTAssertNotNil(card.nextReviewDate)
    }

    func testUpdateCardDifficultyEaseFactorBounds() {
        let card = Card(context: persistenceController.container.viewContext)
        card.interval = 1
        card.easeFactor = Constants.SpacedRepetition.maxEaseFactor

        spacedRepetitionService.updateCardDifficulty(card, rating: .easy)

        XCTAssertEqual(card.easeFactor, Constants.SpacedRepetition.maxEaseFactor, "Ease factor should not exceed max")

        let card2 = Card(context: persistenceController.container.viewContext)
        card2.interval = 1
        card2.easeFactor = Constants.SpacedRepetition.minEaseFactor

        spacedRepetitionService.updateCardDifficulty(card2, rating: .again)

        XCTAssertEqual(card2.easeFactor, Constants.SpacedRepetition.minEaseFactor, "Ease factor should not go below min")
    }

    func testGetCardsDueForReview() {
        let cardSet = CardSet(context: persistenceController.container.viewContext)

        let dueCard = Card(context: persistenceController.container.viewContext)
        dueCard.nextReviewDate = Date().addingTimeInterval(-86400) // Yesterday

        let futureCard = Card(context: persistenceController.container.viewContext)
        futureCard.nextReviewDate = Date().addingTimeInterval(86400) // Tomorrow

        let neverReviewedCard = Card(context: persistenceController.container.viewContext)
        neverReviewedCard.nextReviewDate = nil

        cardSet.addToCards([dueCard, futureCard, neverReviewedCard])

        let dueCards = spacedRepetitionService.getCardsDueForReview(from: cardSet)

        XCTAssertEqual(dueCards.count, 2, "Should return due and never reviewed cards")
        XCTAssertTrue(dueCards.contains(dueCard))
        XCTAssertTrue(dueCards.contains(neverReviewedCard))
        XCTAssertFalse(dueCards.contains(futureCard))
    }

    func testGetNextReviewDate() {
        let card = Card(context: persistenceController.container.viewContext)
        card.interval = 3

        let nextDate = spacedRepetitionService.getNextReviewDate(for: card)
        let expectedDate = Date().addingTimeInterval(3 * Constants.SpacedRepetition.secondsInDay)

        XCTAssertEqual(nextDate.timeIntervalSince1970, expectedDate.timeIntervalSince1970, accuracy: 1.0)
    }
}