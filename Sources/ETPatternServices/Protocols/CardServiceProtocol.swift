import Foundation
import SwiftData
import ETPatternModels

@MainActor
public protocol CardServiceProtocol {
    /// Fetches all available CardSets.
    func fetchCardSets() async throws -> [CardSet]
    
    /// Fetches a CardSet by name and returns grouped cards for display.
    /// - Parameter deckName: The unique name of the CardSet.
    /// - Returns: An array of DeckSection (grouped cards).
    func fetchDeckSections(for deckName: String) async throws -> [DeckSection]
    
    /// Fetches a single card details (if needed separately, not used yet but good practice)
    func fetchCardPreview(id: Int32) async throws -> CardDisplayModel?
    
    /// Deletes a CardSet.
    func deleteCardSet(_ cardSetID: PersistentIdentifier) async throws
    
    /// Creates a new CardSet.
    func createCardSet(name: String) async throws -> CardSet
    
    /// Updates an existing card's content.
    func updateCard(id: Int32, front: String, back: String) async throws
    
    /// Adds a new card to a specific deck.
    func addCard(to deckName: String, front: String, back: String) async throws -> Card
}
