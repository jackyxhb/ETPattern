//
//  Card.swift
//  ETPattern
//
//  Created by admin on 10/01/2026.
//

import Foundation
import SwiftData

@Model
public final class Card {
    @Attribute(.unique) public var id: Int32
    public var front: String
    public var back: String
    public var tags: String?
    public var cardName: String
    public var groupId: Int32
    public var groupName: String
    public var difficulty: Int16
    public var nextReviewDate: Date
    public var interval: Int32
    public var easeFactor: Double
    public var timesReviewed: Int32
    public var timesCorrect: Int32
    public var lastReviewedDate: Date?
    
    public var cardSet: CardSet?

    @Relationship(deleteRule: .nullify, inverse: \StudySession.reviewedCards)
    public var reviewedSessions: [StudySession] = []
    @Relationship(deleteRule: .nullify, inverse: \StudySession.remainingCards)
    public var remainingSessions: [StudySession] = []

    public init(id: Int32, front: String, back: String, cardName: String, groupId: Int32, groupName: String, difficulty: Int16 = 0, nextReviewDate: Date = Date(), interval: Int32 = 1, easeFactor: Double = 2.5, timesReviewed: Int32 = 0, timesCorrect: Int32 = 0) {
        self.id = id
        self.front = front
        self.back = back
        self.cardName = cardName
        self.groupId = groupId
        self.groupName = groupName
        self.difficulty = difficulty
        self.nextReviewDate = nextReviewDate
        self.interval = interval
        self.easeFactor = easeFactor
        self.timesReviewed = timesReviewed
        self.timesCorrect = timesCorrect
    }
}

extension Card {
    public var successRate: Double {
        guard timesReviewed > 0 else { return 0.0 }
        return Double(timesCorrect) / Double(timesReviewed)
    }

    public func recordReview(correct: Bool) {
        timesReviewed += 1
        if correct {
            timesCorrect += 1
        }
        lastReviewedDate = Date()
    }
}
