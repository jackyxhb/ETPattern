import Foundation
import SwiftData
import ETPatternModels
import ETPatternCore

@available(iOS 17, *)
@ModelActor
public actor StudyService: StudyServiceProtocol {
    // modelContainer and modelExecutor are synthesized by @ModelActor
    // init also synthesized
    
    // Custom init if needed? No, standard init(modelContainer:) is generated.

    
    public func fetchActiveSessionID(for cardSetID: PersistentIdentifier) async throws -> PersistentIdentifier? {
        guard let localCardSet = modelContext.model(for: cardSetID) as? CardSet else { return nil }
        let cardSetName = localCardSet.name
        
        let predicate = #Predicate<StudySession> { session in
            session.isActive && session.cardSet?.name == cardSetName
        }
        let descriptor = FetchDescriptor<StudySession>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        let sessions = try modelContext.fetch(descriptor)
        return sessions.first?.persistentModelID
    }
    
    public func createSession(for cardSetID: PersistentIdentifier, strategy: StudyStrategy) async throws -> PersistentIdentifier {
        guard let localCardSet = modelContext.model(for: cardSetID) as? CardSet else {
             throw NSError(domain: "StudyService", code: 404, userInfo: [NSLocalizedDescriptionKey: "CardSet not found"])
        }
        
        let newSession = StudySession(totalCards: Int32(localCardSet.cards.count))
        newSession.cardSet = localCardSet
        newSession.isActive = true
        newSession.strategy = strategy
        newSession.date = Date()
        
        modelContext.insert(newSession)
        try modelContext.save()
        return newSession.persistentModelID
    }
    
    public func saveProgress(sessionID: PersistentIdentifier, currentCardIndex: Int, cardsReviewed: Int) async throws {
        guard let localSession = modelContext.model(for: sessionID) as? StudySession else { return }
        
        localSession.currentCardIndex = Int32(currentCardIndex)
        localSession.cardsReviewed = Int32(cardsReviewed)
        
        try modelContext.save()
    }
    
    public func updateCardDifficulty(cardID: PersistentIdentifier, rating: DifficultyRating, in sessionID: PersistentIdentifier?) async throws {
        guard let localCard = modelContext.model(for: cardID) as? Card else { return }
        
        // Calculate new SRS values
        let previousInterval = localCard.interval
        let previousEaseFactor = localCard.easeFactor
        
        let result = SpacedRepetitionLogic.calculateNextReview(
            currentInterval: localCard.interval,
            currentEaseFactor: localCard.easeFactor,
            rating: rating
        )
        
        // Update Card
        localCard.timesReviewed += 1
        if rating != .again {
            localCard.timesCorrect += 1
        } else {
            localCard.lapses += 1
        }
        localCard.lastReviewedDate = Date()
        localCard.interval = result.interval
        localCard.easeFactor = result.easeFactor
        
         if let nextDate = Calendar.current.date(byAdding: .day, value: Int(localCard.interval), to: Date()) {
            localCard.nextReviewDate = nextDate
        } else {
            localCard.nextReviewDate = Date().addingTimeInterval(TimeInterval(localCard.interval * 86400))
        }
        
        // Create ReviewLog
        let reviewLog = ReviewLog(
            date: Date(),
            rating: rating,
            interval: result.interval,
            easeFactor: result.easeFactor,
            previousInterval: previousInterval,
            previousEaseFactor: previousEaseFactor
        )
        
        localCard.reviewLogs.append(reviewLog)
        reviewLog.card = localCard
        
        if let sID = sessionID, let localSession = modelContext.model(for: sID) as? StudySession {
            localSession.reviewLogs.append(reviewLog)
            reviewLog.studySession = localSession
        }
        
        try modelContext.save()
    }
}
