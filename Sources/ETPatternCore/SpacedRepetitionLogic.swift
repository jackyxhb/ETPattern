//
//  SpacedRepetitionLogic.swift
//  ETPatternCore
//
//  Created by admin on 25/12/2025.
//

import Foundation

public enum DifficultyRating {
    case again
    case easy
}

public struct SpacedRepetitionLogic {
    public struct ReviewResult {
        public let interval: Int32
        public let easeFactor: Double
        
        public init(interval: Int32, easeFactor: Double) {
            self.interval = interval
            self.easeFactor = easeFactor
        }
    }
    
    public static func calculateNextReview(currentInterval: Int32, currentEaseFactor: Double, rating: DifficultyRating) -> ReviewResult {
        var newInterval: Int32 = currentInterval
        var newEaseFactor: Double = currentEaseFactor
        
        switch rating {
        case .again:
            newInterval = 1
            newEaseFactor = max(1.3, currentEaseFactor - 0.2)
        case .easy:
            // interval = interval * easeFactor * 1.5
            let calculatedInterval = Double(currentInterval) * currentEaseFactor * 1.5
            newInterval = Int32(max(1, Int(calculatedInterval)))
            newEaseFactor = min(2.5, currentEaseFactor + 0.1)
        }
        
        return ReviewResult(interval: newInterval, easeFactor: newEaseFactor)
    }
}
