//
//  SpacedRepetitionService.swift
//  ETPattern
//
//  Created by admin on 28/11/2025.
//

import Foundation

enum DifficultyRating {
    case again
    case easy
}

class SpacedRepetitionService {
    func updateCardDifficulty(_ card: Card, rating: DifficultyRating) {
        switch rating {
        case .again:
            card.interval = Constants.SpacedRepetition.againInterval
            card.easeFactor = max(Constants.SpacedRepetition.minEaseFactor, card.easeFactor - Constants.SpacedRepetition.easeDecrement)
        case .easy:
            card.interval = Int32(max(1, Int(Double(card.interval) * card.easeFactor * Constants.SpacedRepetition.easyMultiplier)))
            card.easeFactor = min(Constants.SpacedRepetition.maxEaseFactor, card.easeFactor + Constants.SpacedRepetition.easeIncrement)
        }

        card.nextReviewDate = Date().addingTimeInterval(TimeInterval(card.interval) * Constants.SpacedRepetition.secondsInDay)
    }

    func getCardsDueForReview(from cardSet: CardSet) -> [Card] {
        let now = Date()
        return (cardSet.cards?.allObjects as? [Card])?.filter { card in
            // Cards with no nextReviewDate (never reviewed) or past due dates are due
            card.nextReviewDate == nil || card.nextReviewDate! <= now
        }.sorted { (card1, card2) in
            let date1 = card1.nextReviewDate ?? Date.distantPast
            let date2 = card2.nextReviewDate ?? Date.distantPast
            return date1 < date2
        } ?? []
    }

    func getNextReviewDate(for card: Card) -> Date {
        return Date().addingTimeInterval(TimeInterval(card.interval) * Constants.SpacedRepetition.secondsInDay)
    }
}