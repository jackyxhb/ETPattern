//
//  CardExtensions.swift
//  ETPattern
//
//  Created by admin on 29/11/2025.
//

import Foundation

extension Card {
    var successRate: Double {
        guard timesReviewed > 0 else { return 0.0 }
        return Double(timesCorrect) / Double(timesReviewed)
    }

    func recordReview(correct: Bool) {
        timesReviewed += 1
        if correct {
            timesCorrect += 1
        }
        lastReviewedDate = Date()
    }
}