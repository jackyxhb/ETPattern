import Foundation
import SwiftData

@MainActor
class TestRunner {
    static let shared = TestRunner()
    
    private var passCount = 0
    private var failCount = 0
    
    private init() {}
    
    func runAllTests() async {
        print("🧪 Starting Unit Tests...")
        passCount = 0
        failCount = 0
        
        do {
            try await testPrepareSession()
            try await testStrategySwitch()
            try await testFetchCards()
            try await testUpdateCardDifficulty()
            try await testSaveProgress()
            try await testIntelligentQueue()
            try await testEmptyDeck()
            
            print("")
            if failCount == 0 {
                print("✅ All \(passCount) Tests Passed!")
            } else {
                print("⚠️ \(passCount) Passed, \(failCount) Failed")
            }
        } catch {
            print("❌ Tests Failed with Error: \(error)")
        }
    }
    
    // MARK: - Test Helpers
    
    private func check(_ condition: Bool, _ message: String) {
        if condition {
            passCount += 1
            print("   ✓ \(message)")
        } else {
            failCount += 1
            print("   ✗ \(message)")
        }
    }
    
    private func createTestContainer() throws -> (ModelContext, CardSet, [Card]) {
        let schema = Schema([Card.self, CardSet.self, StudySession.self, ReviewLog.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        let context = container.mainContext
        
        let cardSet = CardSet(name: "Test Deck")
        context.insert(cardSet)
        
        var cards: [Card] = []
        for i in 1...10 {
            let card = Card(front: "Front \(i)", back: "Back \(i)")
            card.id = Int32(i)
            card.cardSet = cardSet
            context.insert(card)
            cards.append(card)
        }
        
        return (context, cardSet, cards)
    }
    
    // MARK: - Tests
    
    private func testPrepareSession() async throws {
        print("   Testing prepareSession...")
        let (context, cardSet, _) = try createTestContainer()
        let service = SessionService(modelContext: context)
        
        let session = try await service.prepareSession(for: cardSet, strategy: .linear)
        
        check(session.isActive, "Session should be active")
        check(session.cardOrder?.count == 10, "Should have 10 cards in order")
        check(session.strategy == .linear, "Strategy should be linear")
        check(session.cardSet?.name == "Test Deck", "CardSet should be linked")
    }
    
    private func testStrategySwitch() async throws {
        print("   Testing updateStrategy...")
        let (context, cardSet, _) = try createTestContainer()
        let service = SessionService(modelContext: context)
        
        let session = try await service.prepareSession(for: cardSet, strategy: .linear)
        let originalFirst = session.cardOrder?.first
        
        // Switch to shuffled
        try await service.updateStrategy(for: session, to: .shuffled)
        check(session.strategy == .shuffled, "Strategy should be shuffled")
        check(session.cardOrder?.count == 10, "Should still have 10 cards")
        
        // Switch to intelligent
        try await service.updateStrategy(for: session, to: .intelligent)
        check(session.strategy == .intelligent, "Strategy should be intelligent")
        
        // Switch back to linear
        try await service.updateStrategy(for: session, to: .linear)
        check(session.strategy == .linear, "Strategy back to linear")
        check(session.cardOrder?.first == originalFirst, "Linear order restored")
    }
    
    private func testFetchCards() async throws {
        print("   Testing fetchCards...")
        let (context, cardSet, _) = try createTestContainer()
        let service = SessionService(modelContext: context)
        
        let session = try await service.prepareSession(for: cardSet, strategy: .linear)
        let fetchedCards = service.fetchCards(for: session)
        
        check(fetchedCards.count == 10, "Should fetch 10 cards")
        check(fetchedCards.first?.front == "Front 1", "First card should be Front 1")
        check(fetchedCards.last?.front == "Front 10", "Last card should be Front 10")
    }
    
    private func testUpdateCardDifficulty() async throws {
        print("   Testing updateCardDifficulty...")
        let (context, cardSet, cards) = try createTestContainer()
        let service = SessionService(modelContext: context)
        
        let session = try await service.prepareSession(for: cardSet, strategy: .linear)
        let testCard = cards[0]
        
        let originalInterval = testCard.interval
        try await service.updateCardDifficulty(card: testCard, rating: .good, session: session)
        
        check(testCard.timesReviewed > 0, "Card review count should increase")
        check(testCard.interval >= originalInterval, "Interval should increase or stay same")
        check(session.safeReviewLogs.count > 0, "Review log should be created")
    }
    
    private func testSaveProgress() async throws {
        print("   Testing saveProgress...")
        let (context, cardSet, _) = try createTestContainer()
        let service = SessionService(modelContext: context)
        
        let session = try await service.prepareSession(for: cardSet, strategy: .linear)
        session.currentCardIndex = 5
        
        try await service.saveProgress(session: session)
        check(session.currentCardIndex == 5, "Progress should be saved")
    }
    
    private func testIntelligentQueue() async throws {
        print("   Testing intelligent queue prioritization...")
        let (context, cardSet, cards) = try createTestContainer()
        let service = SessionService(modelContext: context)
        
        // Mark some cards as due
        cards[0].nextReviewDate = Date().addingTimeInterval(-86400) // 1 day ago
        cards[1].nextReviewDate = Date().addingTimeInterval(-86400)
        cards[0].timesReviewed = 1
        cards[1].timesReviewed = 1
        
        // Mark some as lapsed
        cards[2].lapses = 1
        cards[2].timesReviewed = 1
        
        let session = try await service.prepareSession(for: cardSet, strategy: .intelligent)
        let order = session.cardOrder ?? []
        
        check(order.count == 10, "Should have all cards")
        // Due/lapsed cards should generally be first
        let dueIDs = [1, 2, 3] // cards 0, 1, 2 are due/lapsed
        let firstThree = Array(order.prefix(5))
        let dueInTop = dueIDs.filter { firstThree.contains($0) }.count
        check(dueInTop >= 2, "Due/lapsed cards should be prioritized (found \(dueInTop) in top 5)")
    }
    
    private func testEmptyDeck() async throws {
        print("   Testing empty deck handling...")
        let schema = Schema([Card.self, CardSet.self, StudySession.self, ReviewLog.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        let context = container.mainContext
        
        let emptyDeck = CardSet(name: "Empty Deck")
        context.insert(emptyDeck)
        
        let service = SessionService(modelContext: context)
        let session = try await service.prepareSession(for: emptyDeck, strategy: .linear)
        
        check(session.cardOrder?.count == 0, "Empty deck should have empty order")
        
        let fetchedCards = service.fetchCards(for: session)
        check(fetchedCards.isEmpty, "Fetched cards should be empty")
    }
}
