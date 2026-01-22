import Foundation

/// A thread-safe, immutable representation of a Card for UI display.
/// Decouples the View from the SwiftData @Model class.
public struct CardDisplayModel: Identifiable, Sendable, Hashable {
    public let id: Int32
    public let front: String
    public let back: String
    public let cardName: String
    public let groupName: String
    public let groupId: Int32
    
    public init(id: Int32, front: String, back: String, cardName: String, groupName: String, groupId: Int32) {
        self.id = id
        self.front = front
        self.back = back
        self.cardName = cardName
        self.groupName = groupName
        self.groupId = groupId
    }
    
    public static var empty: CardDisplayModel {
        CardDisplayModel(id: 0, front: "", back: "", cardName: "", groupName: "", groupId: 0)
    }
}

/// A thread-safe representation of a grouped deck section
public struct DeckSection: Identifiable, Sendable, Hashable {
    public var id: String { groupName }
    public let groupName: String
    public let cards: [CardDisplayModel]
    
    public init(groupName: String, cards: [CardDisplayModel]) {
        self.groupName = groupName
        self.cards = cards
    }
}
