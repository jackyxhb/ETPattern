import Foundation
import SwiftData
@testable import ETPatternServices
@testable import ETPatternServices
@testable import ETPatternModels

final class MockStudyService: StudyServiceProtocol, @unchecked Sendable {
    
    // Test Hooks
    var fetchActiveSessionIDReturnValue: PersistentIdentifier?
    var createSessionReturnValue: PersistentIdentifier?
    
    var fetchActiveSessionIDCalled = false
    var createSessionCalled = false
    var saveProgressCalled = false
    var updateCardDifficultyCalled = false
    
    // Captured arguments
    var lastSavedSessionID: PersistentIdentifier?
    var lastUpdatedCardID: PersistentIdentifier?
    var lastRating: DifficultyRating?

    func fetchActiveSessionID(for cardSetID: PersistentIdentifier) async throws -> PersistentIdentifier? {
        fetchActiveSessionIDCalled = true
        return fetchActiveSessionIDReturnValue
    }
    
    func createSession(for cardSetID: PersistentIdentifier, strategy: StudyStrategy) async throws -> PersistentIdentifier {
        createSessionCalled = true
        if let sessionID = createSessionReturnValue {
            return sessionID
        }
        throw NSError(domain: "MockStudyService", code: -1, userInfo: [NSLocalizedDescriptionKey: "createSessionReturnValue not set"])
    }
    
    func saveProgress(sessionID: PersistentIdentifier, currentCardIndex: Int, cardsReviewed: Int) async throws {
        saveProgressCalled = true
        lastSavedSessionID = sessionID
    }
    
    func updateCardDifficulty(cardID: PersistentIdentifier, rating: DifficultyRating, in sessionID: PersistentIdentifier?) async throws {
        updateCardDifficultyCalled = true
        lastUpdatedCardID = cardID
        lastRating = rating
    }
}
