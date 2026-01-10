//
//  SpacedRepetitionService.swift
//  ETPattern
//
//  Created by admin on 28/11/2025.
//

import Foundation
import ETPatternCore
import ETPatternModels
import os

public class SpacedRepetitionService {
    public init() {}

    public func updateCardDifficulty(_ card: Card, rating: DifficultyRating, in session: StudySession? = nil) {
        let previousInterval = card.interval
        let previousEaseFactor = card.easeFactor
        
        let result = SpacedRepetitionLogic.calculateNextReview(
            currentInterval: card.interval,
            currentEaseFactor: card.easeFactor,
            rating: rating
        )
        
        let logger = Logger(subsystem: "com.jack.ETPattern", category: "SRS")
        logger.info("[SRS] Card: \(card.cardName) | Rating: \(String(describing: rating)) | Interval: \(card.interval) -> \(result.interval)")
        
        // Update card stats
        card.timesReviewed += 1
        if rating != .again {
            card.timesCorrect += 1
        } else {
            card.lapses += 1
        }
        card.lastReviewedDate = Date()
        
        // Apply SRS results
        card.interval = result.interval
        card.easeFactor = result.easeFactor
        
        // Calculate next review date using Calendar for accuracy
        if let nextDate = Calendar.current.date(byAdding: .day, value: Int(card.interval), to: Date()) {
            card.nextReviewDate = nextDate
        } else {
            card.nextReviewDate = Date().addingTimeInterval(TimeInterval(card.interval * 86400))
        }
        
        // Create ReviewLog
        let reviewLog = ReviewLog(
            date: Date(),
            rating: rating,
            interval: result.interval,
            easeFactor: result.easeFactor,
            previousInterval: previousInterval,
            previousEaseFactor: previousEaseFactor
        )
        reviewLog.card = card
        reviewLog.studySession = session
        card.reviewLogs.append(reviewLog)
        session?.reviewLogs.append(reviewLog)
    }

    public func getCardsDueForReview(from cardSet: CardSet) -> [Card] {
        let now = Date()
        return cardSet.cards.filter { card in
            // Cards with past due dates are due (nextReviewDate defaults to Date() in Model if not provided)
            return card.nextReviewDate <= now
        }.sorted { (card1, card2) in
            return card1.nextReviewDate < card2.nextReviewDate
        }
    }

    public func getNextReviewDate(for card: Card) -> Date {
        return Date().addingTimeInterval(TimeInterval(card.interval * 86400))
    }
}