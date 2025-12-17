//
//  SpacedRepetitionTests.swift
//  ETPatternTests
//
//  Created by admin on 29/11/2025.
//

import CoreData
import Testing
@testable import ETPattern

@Suite("Spaced Repetition")
struct SpacedRepetitionTests {

    @MainActor
    private func makeTestCard(in context: NSManagedObjectContext) -> Card {
        guard let entity = NSEntityDescription.entity(forEntityName: "Card", in: context) else {
            fatalError("Failed to resolve Card entity")
        }
        let card = Card(entity: entity, insertInto: context)
        card.id = 1
        card.front = "Test Pattern"
        card.cardName = card.front ?? "Test Pattern"
        card.back = "Test Example"
        card.groupId = 0
        card.groupName = ""
        card.difficulty = 0
        card.nextReviewDate = Date()
        card.interval = 1
        card.easeFactor = 2.5
        card.timesReviewed = 0
        card.timesCorrect = 0
        return card
    }

    @MainActor
    @Test
    func updateCardDifficulty_again() {
        let persistenceController = PersistenceController(inMemory: true)
        let service = SpacedRepetitionService()
        let testCard = makeTestCard(in: persistenceController.container.viewContext)
        let initialEaseFactor = testCard.easeFactor

        service.updateCardDifficulty(testCard, rating: .again)

        #expect(testCard.interval == 1)
        #expect(testCard.easeFactor == max(1.3, initialEaseFactor - 0.2))
        #expect(testCard.nextReviewDate != nil)
    }

    @MainActor
    @Test
    func updateCardDifficulty_easy() {
        let persistenceController = PersistenceController(inMemory: true)
        let service = SpacedRepetitionService()
        let testCard = makeTestCard(in: persistenceController.container.viewContext)
        testCard.interval = 2
        let initialEaseFactor = testCard.easeFactor

        service.updateCardDifficulty(testCard, rating: .easy)

        let expectedInterval = Int32(max(1, Int(Double(2) * initialEaseFactor * 1.5)))
        #expect(testCard.interval == expectedInterval)
        #expect(testCard.easeFactor == min(2.5, initialEaseFactor + 0.1))
        #expect(testCard.nextReviewDate != nil)
    }

    @MainActor
    @Test
    func getCardsDueForReview_returnsDueCard() {
        let persistenceController = PersistenceController(inMemory: true)
        let service = SpacedRepetitionService()
        let testCard = makeTestCard(in: persistenceController.container.viewContext)

        guard let cardSetEntity = NSEntityDescription.entity(forEntityName: "CardSet", in: persistenceController.container.viewContext) else {
            fatalError("Failed to resolve CardSet entity")
        }
        let cardSet = CardSet(entity: cardSetEntity, insertInto: persistenceController.container.viewContext)
        cardSet.name = "Test Set"
        cardSet.addToCards(testCard)

        testCard.nextReviewDate = Date().addingTimeInterval(-86400)

        let dueCards = service.getCardsDueForReview(from: cardSet)

        #expect(dueCards.count == 1)
        #expect(dueCards.first === testCard)
    }

    @MainActor
    @Test
    func getCardsDueForReview_returnsEmptyWhenNotDue() {
        let persistenceController = PersistenceController(inMemory: true)
        let service = SpacedRepetitionService()
        let testCard = makeTestCard(in: persistenceController.container.viewContext)

        guard let cardSetEntity = NSEntityDescription.entity(forEntityName: "CardSet", in: persistenceController.container.viewContext) else {
            fatalError("Failed to resolve CardSet entity")
        }
        let cardSet = CardSet(entity: cardSetEntity, insertInto: persistenceController.container.viewContext)
        cardSet.name = "Test Set"
        cardSet.addToCards(testCard)

        testCard.nextReviewDate = Date().addingTimeInterval(86400)
        let dueCards = service.getCardsDueForReview(from: cardSet)

        #expect(dueCards.isEmpty)
    }

    @MainActor
    @Test
    func getCardsDueForReview_newCardIsDue() {
        let persistenceController = PersistenceController(inMemory: true)
        let service = SpacedRepetitionService()
        let testCard = makeTestCard(in: persistenceController.container.viewContext)

        guard let cardSetEntity = NSEntityDescription.entity(forEntityName: "CardSet", in: persistenceController.container.viewContext) else {
            fatalError("Failed to resolve CardSet entity")
        }
        let cardSet = CardSet(entity: cardSetEntity, insertInto: persistenceController.container.viewContext)
        cardSet.name = "Test Set"
        cardSet.addToCards(testCard)

        testCard.nextReviewDate = nil
        let dueCards = service.getCardsDueForReview(from: cardSet)

        #expect(dueCards.count == 1)
        #expect(dueCards.first === testCard)
    }

    @MainActor
    @Test
    func getNextReviewDate_calculatesCorrectly() {
        let persistenceController = PersistenceController(inMemory: true)
        let service = SpacedRepetitionService()
        let testCard = makeTestCard(in: persistenceController.container.viewContext)
        testCard.interval = 3

        let nextReviewDate = service.getNextReviewDate(for: testCard)
        let expectedDate = Date().addingTimeInterval(TimeInterval(3 * 86400))

        #expect(abs(nextReviewDate.timeIntervalSince1970 - expectedDate.timeIntervalSince1970) < 1.0)
    }

    @MainActor
    @Test
    func easeFactorBounds_areEnforced() {
        let persistenceController = PersistenceController(inMemory: true)
        let service = SpacedRepetitionService()
        let testCard = makeTestCard(in: persistenceController.container.viewContext)

        testCard.easeFactor = 1.2
        service.updateCardDifficulty(testCard, rating: .again)
        #expect(testCard.easeFactor == 1.3)

        testCard.easeFactor = 2.5
        service.updateCardDifficulty(testCard, rating: .easy)
        #expect(testCard.easeFactor == 2.5)
    }
}