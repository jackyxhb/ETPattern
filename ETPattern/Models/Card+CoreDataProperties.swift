//
//  Card+CoreDataProperties.swift
//  ETPattern
//
//  Created by GitHub Copilot on 02/12/2025.
//

import Foundation
import CoreData

extension Card {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Card> {
        return NSFetchRequest<Card>(entityName: "Card")
    }

    @NSManaged public var front: String?
    @NSManaged public var back: String?
    @NSManaged public var tags: String?
    @NSManaged public var difficulty: Int16
    @NSManaged public var nextReviewDate: Date?
    @NSManaged public var interval: Int32
    @NSManaged public var easeFactor: Double
    @NSManaged public var timesReviewed: Int32
    @NSManaged public var timesCorrect: Int32
    @NSManaged public var lastReviewedDate: Date?
    @NSManaged public var cardSet: CardSet?
    @NSManaged public var reviewedSessions: NSSet?
    @NSManaged public var remainingSessions: NSSet?
}

// MARK: Generated accessors for reviewedSessions
extension Card {

    @objc(addReviewedSessionsObject:)
    @NSManaged public func addToReviewedSessions(_ value: StudySession)

    @objc(removeReviewedSessionsObject:)
    @NSManaged public func removeFromReviewedSessions(_ value: StudySession)

    @objc(addReviewedSessions:)
    @NSManaged public func addToReviewedSessions(_ values: NSSet)

    @objc(removeReviewedSessions:)
    @NSManaged public func removeFromReviewedSessions(_ values: NSSet)
}

// MARK: Generated accessors for remainingSessions
extension Card {

    @objc(addRemainingSessionsObject:)
    @NSManaged public func addToRemainingSessions(_ value: StudySession)

    @objc(removeRemainingSessionsObject:)
    @NSManaged public func removeFromRemainingSessions(_ value: StudySession)

    @objc(addRemainingSessions:)
    @NSManaged public func addToRemainingSessions(_ values: NSSet)

    @objc(removeRemainingSessions:)
    @NSManaged public func removeFromRemainingSessions(_ values: NSSet)
}

extension Card : Identifiable { }
