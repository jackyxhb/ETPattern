import SwiftData
import ETPatternModels

public protocol StudyServiceProtocol: Sendable {
    func fetchActiveSessionID(for cardSetID: PersistentIdentifier) async throws -> PersistentIdentifier?
    func createSession(for cardSetID: PersistentIdentifier, strategy: StudyStrategy) async throws -> PersistentIdentifier
    // We pass ID of session to update. 
    func saveProgress(sessionID: PersistentIdentifier, currentCardIndex: Int, cardsReviewed: Int) async throws
    // We pass ID of card and session.
    func updateCardDifficulty(cardID: PersistentIdentifier, rating: DifficultyRating, in sessionID: PersistentIdentifier?) async throws
}
