//
//  ReviewLog.swift
//  ETPattern
//
//  Created by admin on 10/01/2026.
//

import Foundation
import SwiftData

@Model
public final class ReviewLog {
    public var date: Date
    public var ratingValue: Int
    public var interval: Int32
    public var easeFactor: Double
    
    // Previous values for reference
    public var previousInterval: Int32
    public var previousEaseFactor: Double
    
    public var card: Card?
    public var studySession: StudySession?
    
    public var rating: DifficultyRating? {
        get { DifficultyRating(rawValue: ratingValue) }
        set { ratingValue = newValue?.rawValue ?? 0 }
    }
    
    public init(
        date: Date = Date(),
        rating: DifficultyRating,
        interval: Int32,
        easeFactor: Double,
        previousInterval: Int32,
        previousEaseFactor: Double
    ) {
        self.date = date
        self.ratingValue = rating.rawValue
        self.interval = interval
        self.easeFactor = easeFactor
        self.previousInterval = previousInterval
        self.previousEaseFactor = previousEaseFactor
    }
}
