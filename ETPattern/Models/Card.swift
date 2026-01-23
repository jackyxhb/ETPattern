//
//  Card.swift
//  ETPattern
//
//  Created by admin on 10/01/2026.
//

import Foundation
import SwiftData

@Model
final class Card {
    var id: Int32 = 0
    var front: String = ""
    var back: String = ""
    var tags: String?
    var cardName: String = ""
    var groupId: Int32 = 0
    var groupName: String = ""
    var difficulty: Int16 = 0
    var nextReviewDate: Date = Date()
    var interval: Int32 = 1
    var easeFactor: Double = 2.5
    var timesReviewed: Int32 = 0
    var timesCorrect: Int32 = 0
    var lastReviewedDate: Date?
    var lapses: Int32 = 0
    
    var cardSet: CardSet?

    @Relationship(deleteRule: .nullify, inverse: \StudySession.reviewedCards)
    var reviewedSessions: [StudySession]? = []
    @Relationship(deleteRule: .nullify, inverse: \StudySession.remainingCards)
    var remainingSessions: [StudySession]? = []
    
    @Relationship(deleteRule: .nullify, inverse: \ReviewLog.card)
    var reviewLogs: [ReviewLog]? = []

    init(
        id: Int32 = 0,
        front: String = "",
        back: String = "",
        cardName: String = "",
        groupId: Int32 = 0,
        groupName: String = "",
        difficulty: Int16 = 0,
        nextReviewDate: Date = Date(),
        interval: Int32 = 1,
        easeFactor: Double = 2.5,
        timesReviewed: Int32 = 0,
        timesCorrect: Int32 = 0
    ) {
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
        self.lapses = 0
    }
}

extension Card {
    var successRate: Double {
        guard timesReviewed > 0 else { return 0.0 }
        return Double(timesCorrect) / Double(timesReviewed)
    }

    func recordReview(correct: Bool) {
        timesReviewed += 1
        if correct {
            timesCorrect += 1
        }
        lastReviewedDate = Date()
    }
    
    var safeReviewedSessions: [StudySession] {
        get { reviewedSessions ?? [] }
        set { reviewedSessions = newValue }
    }
    var safeRemainingSessions: [StudySession] {
        get { remainingSessions ?? [] }
        set { remainingSessions = newValue }
    }
    var safeReviewLogs: [ReviewLog] {
        get { reviewLogs ?? [] }
        set { reviewLogs = newValue }
    }
}
