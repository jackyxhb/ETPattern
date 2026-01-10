//
//  SpacedRepetitionLogic.swift
//  ETPatternCore
//
//  Created by admin on 25/12/2025.
//

import Foundation
import ETPatternModels

public struct SpacedRepetitionLogic {
    public struct ReviewResult {
        public let interval: Int32
        public let easeFactor: Double
        
        public init(interval: Int32, easeFactor: Double) {
            self.interval = interval
            self.easeFactor = easeFactor
        }
    }
    
    public static func calculateNextReview(
        currentInterval: Int32,
        currentEaseFactor: Double,
        rating: DifficultyRating
    ) -> ReviewResult {
        var newInterval: Int32 = 1
        var newEaseFactor: Double = currentEaseFactor
        
        // SM-2 inspired simplified logic
        switch rating {
        case .again:
            newInterval = 1
            newEaseFactor = max(1.3, currentEaseFactor - 0.2)
            
        case .hard:
            // Slower growth for hard items
            let calculated = Double(currentInterval) * 1.2
            newInterval = Int32(max(calculated, Double(currentInterval) + 1))
            newEaseFactor = max(1.3, currentEaseFactor - 0.15)
            
        case .good:
            if currentInterval <= 1 {
                newInterval = 4 // Standard jump for first success
            } else {
                newInterval = Int32(Double(currentInterval) * currentEaseFactor)
            }
            // Ease factor remains stable for "good"
            
        case .easy:
            if currentInterval <= 1 {
                newInterval = 7 // Aggressive jump for easy new items
            } else {
                let calculated = Double(currentInterval) * currentEaseFactor * 1.3
                newInterval = Int32(max(calculated, Double(currentInterval) + 2))
            }
            newEaseFactor = min(2.5, currentEaseFactor + 0.15)
        }
        
        // Cap interval to a reasonable max (e.g., 3650 days / 10 years)
        newInterval = min(3650, newInterval)
        
        return ReviewResult(interval: newInterval, easeFactor: newEaseFactor)
    }
}
