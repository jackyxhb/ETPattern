//
//  SpacedRepetitionService.swift
//  ETPattern
//
//  Created by admin on 28/11/2025.
//

import Foundation
import ETPatternCore
import os

enum DifficultyRating {
    case again
    case easy
}

class SpacedRepetitionService {
    func updateCardDifficulty(_ card: Card, rating: DifficultyRating) {
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

    func getCardsDueForReview(from cardSet: CardSet) -> [Card] {
        let now = Date()
        return (cardSet.cards?.allObjects as? [Card])?.filter { card in
            // Cards with no nextReviewDate (never reviewed) or past due dates are due
            guard let nextReviewDate = card.nextReviewDate else { return true }
            return nextReviewDate <= now
        }.sorted { (card1, card2) in
            let date1 = card1.nextReviewDate ?? Date.distantPast
            let date2 = card2.nextReviewDate ?? Date.distantPast
            return date1 < date2
        } ?? []
    }

    func getNextReviewDate(for card: Card) -> Date {
        return Date().addingTimeInterval(TimeInterval(card.interval * 86400))
    }
}