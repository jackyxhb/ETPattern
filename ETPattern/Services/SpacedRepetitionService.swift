//
//  SpacedRepetitionService.swift
//  ETPattern
//
//  Created by admin on 28/11/2025.
//

import Foundation
import os

class SpacedRepetitionService {
    init() {}

    func updateCardDifficulty(_ card: Card, rating: DifficultyRating, in session: StudySession? = nil) {
        let previousInterval = card.interval
        let previousEaseFactor = card.easeFactor // Legacy tracking
        
        // Use new FSRS Logic (stateful)
        let result = SpacedRepetitionLogic.calculateNextReview(
            card: card,
            rating: rating
        )
        
        let logger = Logger(subsystem: "com.jack.ETPattern", category: "SRS")
        logger.info("[FSRS] Card: \(card.cardName) | Rating: \(String(describing: rating)) | S: \(card.stability) -> \(result.stability) | D: \(card.fsrsDifficulty) -> \(result.difficulty) | Int: \(card.interval) -> \(result.interval)")
        
        // Update card stats
        card.timesReviewed += 1
        if rating != .again {
            card.timesCorrect += 1
        } else {
            card.lapses += 1
        }
        card.lastReviewedDate = Date()
        
        // Apply FSRS results
        card.interval = result.interval
        card.stability = result.stability
        card.fsrsDifficulty = result.difficulty
        card.state = result.state
        card.scheduledDays = Int32(result.interval)
        
        // Safe mapping to legacy field for compatibility if needed (S replace EF?) or just leave EF alone
        // card.easeFactor = result.stability // Optional: depending on if UI uses this
        
        // set nextReviewDate directly from result
        card.nextReviewDate = result.scheduledDate
        
        // Create ReviewLog
        let reviewLog = ReviewLog(
            date: Date(),
            rating: rating,
            interval: result.interval,
            easeFactor: result.stability, // Storing Stability in legacy easeFactor column for logs
            previousInterval: previousInterval,
            previousEaseFactor: previousEaseFactor
        )
        reviewLog.card = card
        reviewLog.studySession = session
        card.safeReviewLogs.append(reviewLog)
        session?.safeReviewLogs.append(reviewLog)
    }

    func getCardsDueForReview(from cardSet: CardSet) -> [Card] {
        let now = Date()
        return cardSet.safeCards.filter { card in
            // Cards with past due dates are due (nextReviewDate defaults to Date() in Model if not provided)
            return card.nextReviewDate <= now
        }.sorted { (card1, card2) in
            return card1.nextReviewDate < card2.nextReviewDate
        }
    }

    func getNextReviewDate(for card: Card) -> Date {
        return Date().addingTimeInterval(TimeInterval(card.interval * 86400))
    }
}