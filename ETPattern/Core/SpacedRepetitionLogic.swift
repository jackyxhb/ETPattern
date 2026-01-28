//
//  SpacedRepetitionLogic.swift
//  ETPatternCore
//
//  Created by admin on 25/12/2025.
//

import Foundation

struct SpacedRepetitionLogic {
    // Shared Scheduler Instance
    private static let scheduler = FSRSScheduler()
    
    struct ReviewResult {
        let interval: Int32
        let stability: Double
        let difficulty: Double
        let state: Int32
        let scheduledDate: Date
    }
    
    @MainActor
    static func calculateNextReview(
        card: Card,
        rating: DifficultyRating
    ) -> ReviewResult {
        let now = Date()
        
        let info = scheduler.schedule(card: card, now: now, rating: rating)
        
        // Determine new state
        // If Rating is 'Again', usually go to 'Relearning' or 'Learning'
        // If 'Good'/'Easy' and was Learning, go to Review.
        var newState = card.state
        if rating == .again {
            newState = 3 // Relearning
        } else if card.state == 0 || card.state == 1 {
            newState = 2 // Review
        }
        
        return ReviewResult(
            interval: Int32(info.interval),
            stability: info.stability,
            difficulty: info.difficulty,
            state: newState,
            scheduledDate: info.scheduledDate
        )
    }
}
