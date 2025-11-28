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
            card.interval = 1
            card.easeFactor = max(1.3, card.easeFactor - 0.2)
        case .easy:
            card.interval = Int32(max(1, Int(Double(card.interval) * card.easeFactor * 1.5)))
            card.easeFactor = min(2.5, card.easeFactor + 0.1)
        }

        card.nextReviewDate = Date().addingTimeInterval(TimeInterval(card.interval * 86400))
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
        return Date().addingTimeInterval(TimeInterval(card.interval * 86400))
    }
}