//
//  StudySession.swift
//  ETPattern
//
//  Created by admin on 10/01/2026.
//

import Foundation
import SwiftData

@Model
final class StudySession {
    var date: Date = Date()
    var cardsReviewed: Int32 = 0
    var correctCount: Int32 = 0
    var isActive: Bool = false
    var currentCardIndex: Int32 = 0
    var currentCardID: Int32?
    var totalCards: Int32 = 0
    
    var cardSet: CardSet?
    
    var reviewedCards: [Card]? = []
    var remainingCards: [Card]? = []
    
    @Relationship(deleteRule: .cascade, inverse: \ReviewLog.studySession)
    var reviewLogs: [ReviewLog]? = []
    
    var strategyValue: String = StudyStrategy.intelligent.rawValue
    var cardOrder: [Int] = []

    var strategy: StudyStrategy {
        get { StudyStrategy(rawValue: strategyValue) ?? .intelligent }
        set { strategyValue = newValue.rawValue }
    }

    init(date: Date = Date(), cardsReviewed: Int32 = 0, correctCount: Int32 = 0, isActive: Bool = false, currentCardIndex: Int32 = 0, totalCards: Int32 = 0) {
        self.date = date
        self.cardsReviewed = cardsReviewed
        self.correctCount = correctCount
        self.isActive = isActive
        self.currentCardIndex = currentCardIndex
        self.totalCards = totalCards
    }
}

extension StudySession {
    var safeReviewedCards: [Card] {
        get { reviewedCards ?? [] }
        set { reviewedCards = newValue }
    }
    var safeRemainingCards: [Card] {
        get { remainingCards ?? [] }
        set { remainingCards = newValue }
    }
    var safeReviewLogs: [ReviewLog] {
        get { reviewLogs ?? [] }
        set { reviewLogs = newValue }
    }
}
