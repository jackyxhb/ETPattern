//
//  Card.swift
//  ETPattern
//
//  Created by admin on 29/11/2025.
//

import Foundation
import CoreData

@objc(Card)
public class Card: NSManagedObject {

}

extension Card {
    // Computed properties for card statistics
    var timesReviewed: Int32 {
        get {
            return self.value(forKey: "timesReviewed") as? Int32 ?? 0
        }
        set {
            self.setValue(newValue, forKey: "timesReviewed")
        }
    }

    var timesCorrect: Int32 {
        get {
            return self.value(forKey: "timesCorrect") as? Int32 ?? 0
        }
        set {
            self.setValue(newValue, forKey: "timesCorrect")
        }
    }

    var successRate: Double {
        guard timesReviewed > 0 else { return 0.0 }
        return Double(timesCorrect) / Double(timesReviewed)
    }

    var lastReviewedDate: Date? {
        get {
            return self.value(forKey: "lastReviewedDate") as? Date
        }
        set {
            self.setValue(newValue, forKey: "lastReviewedDate")
        }
    }

    func recordReview(correct: Bool) {
        timesReviewed += 1
        if correct {
            timesCorrect += 1
        }
        lastReviewedDate = Date()
    }
}