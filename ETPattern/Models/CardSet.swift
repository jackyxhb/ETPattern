//
//  CardSet.swift
//  ETPattern
//
//  Created by admin on 10/01/2026.
//

import Foundation
import SwiftData

@Model
final class CardSet {
    var name: String = "Unknown Deck"
    var createdDate: Date = Date()
    
    @Relationship(deleteRule: .cascade, inverse: \Card.cardSet)
    var cards: [Card]? = []
    
    @Relationship(deleteRule: .cascade, inverse: \StudySession.cardSet)
    var studySessions: [StudySession]? = []

    init(name: String = "Unknown Deck", createdDate: Date = Date()) {
        self.name = name
        self.createdDate = createdDate
    }
}

extension CardSet {
    var safeCards: [Card] {
        get { cards ?? [] }
        set { cards = newValue }
    }
    var safeStudySessions: [StudySession] {
        get { studySessions ?? [] }
        set { studySessions = newValue }
    }
}
