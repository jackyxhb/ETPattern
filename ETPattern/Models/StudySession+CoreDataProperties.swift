//
//  StudySession+CoreDataProperties.swift
//  ETPattern
//
//  Created by GitHub Copilot on 02/12/2025.
//

import Foundation
import CoreData

extension StudySession {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StudySession> {
        return NSFetchRequest<StudySession>(entityName: "StudySession")
    }

    @NSManaged public var date: Date?
    @NSManaged public var cardsReviewed: Int32
    @NSManaged public var correctCount: Int32
    @NSManaged public var isActive: Bool
    @NSManaged public var currentCardIndex: Int32
    @NSManaged public var totalCards: Int32
    @NSManaged public var cardSet: CardSet?
    @NSManaged public var reviewedCards: NSSet?
    @NSManaged public var remainingCards: NSSet?
}

// MARK: Generated accessors for reviewedCards
extension StudySession {

    @objc(addReviewedCardsObject:)
    @NSManaged public func addToReviewedCards(_ value: Card)

    @objc(removeReviewedCardsObject:)
    @NSManaged public func removeFromReviewedCards(_ value: Card)

    @objc(addReviewedCards:)
    @NSManaged public func addToReviewedCards(_ values: NSSet)

    @objc(removeReviewedCards:)
    @NSManaged public func removeFromReviewedCards(_ values: NSSet)
}

// MARK: Generated accessors for remainingCards
extension StudySession {

    @objc(addRemainingCardsObject:)
    @NSManaged public func addToRemainingCards(_ value: Card)

    @objc(removeRemainingCardsObject:)
    @NSManaged public func removeFromRemainingCards(_ value: Card)

    @objc(addRemainingCards:)
    @NSManaged public func addToRemainingCards(_ values: NSSet)

    @objc(removeRemainingCards:)
    @NSManaged public func removeFromRemainingCards(_ values: NSSet)
}

extension StudySession : Identifiable { }
