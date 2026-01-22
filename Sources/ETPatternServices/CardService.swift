import Foundation
import SwiftData
import ETPatternModels

/// Service responsible for fetching and processing Card data.
/// Uses @MainActor since SwiftData models are not Sendable.
@MainActor
public final class CardService: CardServiceProtocol {
    
    private let modelContainer: ModelContainer
    
    public init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
    
    public func fetchCardSets() async throws -> [CardSet] {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<CardSet>(sortBy: [SortDescriptor(\.createdDate, order: .reverse)])
        return try context.fetch(descriptor)
    }
    
    public func fetchDeckSections(for deckName: String) async throws -> [DeckSection] {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<CardSet>(
            predicate: #Predicate { $0.name == deckName }
        )
        
        guard let cardSet = try context.fetch(descriptor).first else {
            throw NSError(domain: "CardService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Deck not found"])
        }
        
        // Perform sorting and grouping
        let cards = cardSet.cards
        let sortedCards = cards.sorted { ($0.id, $0.front) < ($1.id, $1.front) }
        
        let groupedDictionary = Dictionary(grouping: sortedCards) { $0.groupName }
        let sortedGroupNames = groupedDictionary.keys.sorted { name1, name2 in
            let group1First = groupedDictionary[name1]?.first
            let group2First = groupedDictionary[name2]?.first
            let id1 = group1First?.groupId ?? Int32.max
            let id2 = group2First?.groupId ?? Int32.max
            return id1 < id2
        }
        
        var sections: [DeckSection] = []
        
        for name in sortedGroupNames {
            if let groupCards = groupedDictionary[name] {
                let displayCards = groupCards.map { card in
                    CardDisplayModel(
                        id: card.id,
                        front: card.front,
                        back: card.back,
                        cardName: card.cardName,
                        groupName: card.groupName,
                        groupId: card.groupId
                    )
                }
                sections.append(DeckSection(groupName: name, cards: displayCards))
            }
        }
        
        return sections
    }
    
    public func fetchCardPreview(id: Int32) async throws -> CardDisplayModel? {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<Card>(
            predicate: #Predicate { $0.id == id }
        )
        
        if let card = try context.fetch(descriptor).first {
            return CardDisplayModel(
                id: card.id,
                front: card.front,
                back: card.back,
                cardName: card.cardName,
                groupName: card.groupName,
                groupId: card.groupId
            )
        }
        return nil
    }
    
    public func deleteCardSet(_ cardSetID: PersistentIdentifier) async throws {
        let context = ModelContext(modelContainer)
        if let cardSet = context.model(for: cardSetID) as? CardSet {
            context.delete(cardSet)
            try context.save()
        }
    }
    
    public func createCardSet(name: String) async throws -> CardSet {
        let context = ModelContext(modelContainer)
        let newSet = CardSet(name: name)
        context.insert(newSet)
        try context.save()
        return newSet
    }
    
    public func updateCard(id: Int32, front: String, back: String) async throws {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<Card>(
            predicate: #Predicate { $0.id == id }
        )
        
        guard let card = try context.fetch(descriptor).first else {
            throw NSError(domain: "CardService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Card not found"])
        }
        
        card.front = front
        card.back = back
        try context.save()
    }
    
    public func addCard(to deckName: String, front: String, back: String) async throws -> Card {
        let context = ModelContext(modelContainer)
        
        // Find Deck
        let deckDescriptor = FetchDescriptor<CardSet>(
            predicate: #Predicate { $0.name == deckName }
        )
        guard let cardSet = try context.fetch(deckDescriptor).first else {
             throw NSError(domain: "CardService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Deck not found"])
        }
        
        // Generate new ID (one higher than current max)
        let allCardsDescriptor = FetchDescriptor<Card>()
        let allCards = try context.fetch(allCardsDescriptor)
        let nextID = (allCards.map { $0.id }.max() ?? 0) + 1
        
        // Create Card
        let newCard = Card(
            id: nextID,
            front: front,
            back: back,
            cardName: "", // Optional, can be derived
            groupId: 0,
            groupName: "Default"
        )
        
        newCard.cardSet = cardSet
        cardSet.cards.append(newCard)
        context.insert(newCard)
        try context.save()
        
        return newCard
    }
}
