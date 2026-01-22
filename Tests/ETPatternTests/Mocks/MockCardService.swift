import Foundation
import SwiftData
@testable import ETPatternModels
@testable import ETPatternServices

final class MockCardService: CardServiceProtocol, @unchecked Sendable {
    var fetchCardSetsCalled = false
    var fetchDeckSectionsCalled = false
    var fetchCardPreviewCalled = false
    var deleteCardSetCalled = false
    var createCardSetCalled = false
    var updateCardCalled = false
    var addCardCalled = false
    
    var lastUpdatedID: Int32?
    var lastUpdatedFront: String?
    var lastUpdatedBack: String?
    
    var lastAddedDeckName: String?
    var lastAddedFront: String?
    var lastAddedBack: String?

    func fetchCardSets() async throws -> [CardSet] {
        fetchCardSetsCalled = true
        return []
    }
    
    func fetchDeckSections(for deckName: String) async throws -> [DeckSection] {
        fetchDeckSectionsCalled = true
        return []
    }
    
    func fetchCardPreview(id: Int32) async throws -> CardDisplayModel? {
        fetchCardPreviewCalled = true
        return nil
    }
    
    func deleteCardSet(_ cardSetID: PersistentIdentifier) async throws {
        deleteCardSetCalled = true
    }
    
    func createCardSet(name: String) async throws -> CardSet {
        createCardSetCalled = true
        return CardSet(name: name)
    }
    
    func updateCard(id: Int32, front: String, back: String) async throws {
        updateCardCalled = true
        lastUpdatedID = id
        lastUpdatedFront = front
        lastUpdatedBack = back
    }
    
    func addCard(to deckName: String, front: String, back: String) async throws -> Card {
        addCardCalled = true
        lastAddedDeckName = deckName
        lastAddedFront = front
        lastAddedBack = back
        return Card(id: 1, front: front, back: back)
    }
}
