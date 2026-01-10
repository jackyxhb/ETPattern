//
//  CardSet.swift
//  ETPattern
//
//  Created by admin on 10/01/2026.
//

import Foundation
import SwiftData

@Model
public final class CardSet {
    @Attribute(.unique) public var name: String
    public var createdDate: Date
    
    @Relationship(deleteRule: .cascade, inverse: \Card.cardSet)
    public var cards: [Card] = []
    
    @Relationship(deleteRule: .cascade, inverse: \StudySession.cardSet)
    public var studySessions: [StudySession] = []

    public init(name: String, createdDate: Date = Date()) {
        self.name = name
        self.createdDate = createdDate
    }
}
