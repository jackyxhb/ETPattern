//
//  ReviewLog.swift
//  ETPattern
//
//  Created by admin on 10/01/2026.
//

import Foundation
import SwiftData

@Model
final class ReviewLog {
    var date: Date = Date()
    var ratingValue: Int = 0
    var interval: Int32 = 0
    var easeFactor: Double = 2.5
    
    // Previous values for reference
    var previousInterval: Int32 = 0
    var previousEaseFactor: Double = 2.5
    
    var card: Card?
    var studySession: StudySession?
    
    var rating: DifficultyRating? {
        get { DifficultyRating(rawValue: ratingValue) }
        set { ratingValue = newValue?.rawValue ?? 0 }
    }
    
    init(
        date: Date = Date(),
        rating: DifficultyRating = .good,
        interval: Int32 = 0,
        easeFactor: Double = 2.5,
        previousInterval: Int32 = 0,
        previousEaseFactor: Double = 2.5
    ) {
        self.date = date
        self.ratingValue = rating.rawValue
        self.interval = interval
        self.easeFactor = easeFactor
        self.previousInterval = previousInterval
        self.previousEaseFactor = previousEaseFactor
    }
}
