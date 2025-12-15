//
//  SpacedRepetitionTests.swift
//  ETPatternTests
//
//  Created by admin on 29/11/2025.
//

import XCTest
import CoreData
@testable import ETPattern

class SpacedRepetitionTests: XCTestCase {

    var persistenceController: PersistenceController!
    var spacedRepetitionService: SpacedRepetitionService!
    var testCard: Card!

    override func setUp() {
        super.setUp()
        persistenceController = PersistenceController(inMemory: true)
        spacedRepetitionService = SpacedRepetitionService()

        // Create a test card
        testCard = Card(context: persistenceController.container.viewContext)
        testCard.front = "Test Pattern"
        testCard.back = "Test Example"
        testCard.difficulty = 0
        testCard.nextReviewDate = Date()
        testCard.interval = 1
        testCard.easeFactor = Constants.SpacedRepetition.defaultEaseFactor
    }

    override func tearDown() {
        persistenceController = nil
        spacedRepetitionService = nil
        testCard = nil
        super.tearDown()
    }

    func testUpdateCardDifficulty_Again() {
        // Given
        let initialInterval = testCard.interval
        let initialEaseFactor = testCard.easeFactor

        // When
        spacedRepetitionService.updateCardDifficulty(testCard, rating: .again)

        // Then
        XCTAssertEqual(testCard.interval, Constants.SpacedRepetition.againInterval, "Interval should reset to 1 for 'again' rating")
        XCTAssertEqual(testCard.easeFactor, max(Constants.SpacedRepetition.minEaseFactor, initialEaseFactor - Constants.SpacedRepetition.easeDecrement), "Ease factor should decrease for 'again' rating")
        XCTAssertNotNil(testCard.nextReviewDate, "Next review date should be set")
    }

    func testUpdateCardDifficulty_Easy() {
        // Given
        testCard.interval = 2
        let initialEaseFactor = testCard.easeFactor

        // When
        spacedRepetitionService.updateCardDifficulty(testCard, rating: .easy)

        // Then
        let expectedInterval = Int32(max(1, Int(Double(2) * initialEaseFactor * Constants.SpacedRepetition.easyMultiplier)))
        XCTAssertEqual(testCard.interval, expectedInterval, "Interval should increase for 'easy' rating")
        XCTAssertEqual(testCard.easeFactor, min(Constants.SpacedRepetition.maxEaseFactor, initialEaseFactor + Constants.SpacedRepetition.easeIncrement), "Ease factor should increase for 'easy' rating")
        XCTAssertNotNil(testCard.nextReviewDate, "Next review date should be set")
    }

    func testGetCardsDueForReview() {
        // Given
        let cardSet = CardSet(context: persistenceController.container.viewContext)
        cardSet.name = "Test Set"
        cardSet.addToCards(testCard)

        // Set card as due (past date)
        testCard.nextReviewDate = Date().addingTimeInterval(-86400) // Yesterday

        // When
        let dueCards = spacedRepetitionService.getCardsDueForReview(from: cardSet)

        // Then
        XCTAssertEqual(dueCards.count, 1, "Should return 1 due card")
        XCTAssertEqual(dueCards.first, testCard, "Should return the test card")
    }

    func testGetCardsDueForReview_NoDueCards() {
        // Given
        let cardSet = CardSet(context: persistenceController.container.viewContext)
        cardSet.name = "Test Set"
        cardSet.addToCards(testCard)

        // Set card as not due (future date)
        testCard.nextReviewDate = Date().addingTimeInterval(86400) // Tomorrow

        // When
        let dueCards = spacedRepetitionService.getCardsDueForReview(from: cardSet)

        // Then
        XCTAssertEqual(dueCards.count, 0, "Should return no due cards")
    }

    func testGetCardsDueForReview_NewCard() {
        // Given
        let cardSet = CardSet(context: persistenceController.container.viewContext)
        cardSet.name = "Test Set"
        cardSet.addToCards(testCard)

        // New card (no nextReviewDate)
        testCard.nextReviewDate = nil

        // When
        let dueCards = spacedRepetitionService.getCardsDueForReview(from: cardSet)

        // Then
        XCTAssertEqual(dueCards.count, 1, "New cards should be due for review")
        XCTAssertEqual(dueCards.first, testCard, "Should return the new card")
    }

    func testGetNextReviewDate() {
        // Given
        testCard.interval = 3

        // When
        let nextReviewDate = spacedRepetitionService.getNextReviewDate(for: testCard)

        // Then
        let expectedDate = Date().addingTimeInterval(TimeInterval(3 * 86400))
        XCTAssertEqual(nextReviewDate.timeIntervalSince1970, expectedDate.timeIntervalSince1970, accuracy: 1.0, "Next review date should be calculated correctly")
    }

    func testEaseFactorBounds() {
        // Test minimum ease factor
        testCard.easeFactor = 1.2
        spacedRepetitionService.updateCardDifficulty(testCard, rating: .again)
        XCTAssertEqual(testCard.easeFactor, 1.3, "Ease factor should not go below minimum")

        // Test maximum ease factor
        testCard.easeFactor = 2.5
        spacedRepetitionService.updateCardDifficulty(testCard, rating: .easy)
        XCTAssertEqual(testCard.easeFactor, 2.5, "Ease factor should not go above maximum")
    }

    func testError_InvalidCardData() {
        // Test with card that has invalid interval
        testCard.interval = -1
        spacedRepetitionService.updateCardDifficulty(testCard, rating: .easy)

        // Should handle gracefully, perhaps reset to valid values
        XCTAssertGreaterThanOrEqual(testCard.interval, 1, "Interval should be valid after update")
    }

    func testIntegration_SpacedRepetitionWithMultipleCards() {
        // Create multiple cards
        let card2 = Card(context: persistenceController.container.viewContext)
        card2.front = "Test Pattern 2"
        card2.back = "Test Example 2"
        card2.difficulty = 0
        card2.nextReviewDate = Date()
        card2.interval = 1
        card2.easeFactor = Constants.SpacedRepetition.defaultEaseFactor

        let cardSet = CardSet(context: persistenceController.container.viewContext)
        cardSet.name = "Multi Card Test"
        cardSet.addToCards([testCard, card2])

        // Get due cards
        let dueCards = spacedRepetitionService.getCardsDueForReview(from: cardSet)
        XCTAssertEqual(dueCards.count, 2, "Both new cards should be due")

        // Review first card as easy
        spacedRepetitionService.updateCardDifficulty(dueCards[0], rating: .easy)

        // Review second as again
        spacedRepetitionService.updateCardDifficulty(dueCards[1], rating: .again)

        // Check intervals are different
        XCTAssertGreaterThan(dueCards[0].interval, dueCards[1].interval, "Easy card should have longer interval than again card")
    }
}