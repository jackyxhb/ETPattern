//
//  SessionService.swift
//  ETPattern
//
//  Created by admin on 28/01/2026.
//

import Foundation
import SwiftData
import SwiftUI

protocol SessionServiceProtocol: Sendable {
    @MainActor func prepareSession(for cardSet: CardSet, strategy: StudyStrategy) async throws -> StudySession
    @MainActor func saveProgress(session: StudySession) async throws
    @MainActor func updateCardDifficulty(card: Card, rating: DifficultyRating, session: StudySession) async throws
    @MainActor func fetchCards(for session: StudySession) -> [Card]
    @MainActor func updateStrategy(for session: StudySession, to strategy: StudyStrategy) async throws
}

@MainActor
final class SessionService: SessionServiceProtocol {
    private let modelContext: ModelContext
    private let spacedRepetitionService = SpacedRepetitionService()
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func prepareSession(for cardSet: CardSet, strategy: StudyStrategy) async throws -> StudySession {
        // 1. Check for active existing session
        let name = cardSet.name
        let descriptor = FetchDescriptor<StudySession>(
            predicate: #Predicate<StudySession> { $0.isActive && $0.cardSet?.name == name },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        if let existingSession = try modelContext.fetch(descriptor).first {
             // If strategy changed, we might need to re-shuffle, but for now let's respect the saved session
            return existingSession
        }
        
        // 2. Create new session
        let newSession = StudySession(totalCards: Int32(cardSet.safeCards.count))
        newSession.cardSet = cardSet
        newSession.isActive = true
        newSession.strategy = strategy
        modelContext.insert(newSession)
        
        // 3. Generate Queue
        let cardIDs = generateQueue(for: cardSet, strategy: strategy)
        newSession.cardOrder = cardIDs
        
        try modelContext.save()
        return newSession
    }
    
    func saveProgress(session: StudySession) async throws {
        try modelContext.save()
    }
    
    func updateCardDifficulty(card: Card, rating: DifficultyRating, session: StudySession) async throws {
        // Delegate to pure SRS logic
        spacedRepetitionService.updateCardDifficulty(card, rating: rating, in: session)
        
        // Update session stats
        let logs = session.safeReviewLogs
        session.correctCount = Int32(logs.filter { $0.ratingValue >= 2 }.count)
        
        try modelContext.save()
    }
    
    func fetchCards(for session: StudySession) -> [Card] {
        guard let cardSet = session.cardSet, let order = session.cardOrder else { return [] }
        
        let allCards = cardSet.safeCards
        let cardDict = Dictionary(allCards.map { (Int($0.id), $0) }, uniquingKeysWith: { first, _ in first })
        
        return order.compactMap { cardDict[$0] }
    }
    
    func updateStrategy(for session: StudySession, to strategy: StudyStrategy) async throws {
        guard let cardSet = session.cardSet, let currentOrder = session.cardOrder else { return }
        
        // 1. Capture current card ID if any
        let currentIndex = Int(session.currentCardIndex)
        let currentCardID = (currentIndex >= 0 && currentIndex < currentOrder.count) ? currentOrder[currentIndex] : nil
        
        // 2. Generate new queue
        let newOrder = generateQueue(for: cardSet, strategy: strategy)
        
        // 3. Find new index for current card
        var newIndex = 0
        if let targetID = currentCardID, let foundIndex = newOrder.firstIndex(of: targetID) {
            newIndex = foundIndex
        }
        
        // 4. Update session
        session.strategy = strategy
        session.cardOrder = newOrder
        session.currentCardIndex = Int32(newIndex)
        
        try modelContext.save()
    }

    // MARK: - Internal Logic
    
    private func generateQueue(for cardSet: CardSet, strategy: StudyStrategy) -> [Int] {
        let allCards = cardSet.safeCards
        
        switch strategy {
        case .linear:
            return allCards.sorted { $0.id < $1.id }.map { Int($0.id) }
            
        case .shuffled:
            return allCards.map { Int($0.id) }.shuffled()
            
        case .intelligent:
            return generateIntelligentQueue(allCards: allCards)
        }
    }
    
    private func generateIntelligentQueue(allCards: [Card]) -> [Int] {
        let now = Date()
        
        // 1. Due/Overdue or Lapsed
        let dueCards = allCards.filter { ( $0.nextReviewDate <= now || $0.lapses > 0) && $0.timesReviewed > 0 }
        
        // 2. New cards
        let newCards = allCards.filter { $0.timesReviewed == 0 }
        
        // 3. The rest (Review later)
        let remainingCards = allCards.filter { !dueCards.contains($0) && !newCards.contains($0) }
        
        // Interleave for variety
        return dueCards.map { Int($0.id) }.shuffled() +
               newCards.map { Int($0.id) }.shuffled() +
               remainingCards.map { Int($0.id) }.shuffled()
    }
}
