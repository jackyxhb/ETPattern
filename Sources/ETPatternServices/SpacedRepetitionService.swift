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

public enum DifficultyRating {
    case again
    case easy
}

public class SpacedRepetitionService {
    public init() {}

    public func updateCardDifficulty(_ card: Card, rating: DifficultyRating) {
        // Map local rating to Core rating
        let coreRating: ETPatternCore.DifficultyRating
        switch rating {
        case .again: coreRating = .again
        case .easy: coreRating = .easy
        }
        
        let result = SpacedRepetitionLogic.calculateNextReview(
            currentInterval: card.interval,
            currentEaseFactor: card.easeFactor,
            rating: coreRating
        )
        
        let logger = Logger(subsystem: "com.jack.ETPattern", category: "SRS")
        let ratingDesc = String(describing: rating)
        let msg1 = "[SRS-DEBUG] Updating card '\(card.cardName)' - Rating: \(ratingDesc)"
        let msg2 = "[SRS-DEBUG] Old Interval: \(card.interval), Ease: \(card.easeFactor)"
        let msg3 = "[SRS-DEBUG] New Interval: \(result.interval), Ease: \(result.easeFactor)"
        
        logger.info("\(msg1)")
        logger.info("\(msg2)")
        logger.info("\(msg3)")
        
        card.interval = result.interval
        card.easeFactor = result.easeFactor
        
        card.nextReviewDate = Date().addingTimeInterval(TimeInterval(card.interval * 86400))
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