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
    @NSManaged public var id: Int32
    @NSManaged public var front: String
    @NSManaged public var back: String
    @NSManaged public var tags: String?
    @NSManaged public var cardName: String
    @NSManaged public var groupId: Int32
    @NSManaged public var groupName: String
    @NSManaged public var difficulty: Int16
    @NSManaged public var nextReviewDate: Date
    @NSManaged public var interval: Int32
    @NSManaged public var easeFactor: Double
    @NSManaged public var timesReviewed: Int32
    @NSManaged public var timesCorrect: Int32
    @NSManaged public var lastReviewedDate: Date?

    @NSManaged public var cardSet: CardSet?
    @NSManaged public var reviewedSessions: NSSet?
    @NSManaged public var remainingSessions: NSSet?
}

extension Card {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Card> {
        return NSFetchRequest<Card>(entityName: "Card")
    }
}