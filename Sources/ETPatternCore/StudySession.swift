//
//  StudySession.swift
//  ETPattern
//
//  Created by admin on 29/11/2025.
//

import Foundation
import CoreData

@objc(StudySession)
public class StudySession: NSManagedObject {
    @NSManaged public var date: Date
    @NSManaged public var cardsReviewed: Int32
    @NSManaged public var correctCount: Int32
    @NSManaged public var isActive: Bool
    @NSManaged public var currentCardIndex: Int32
    @NSManaged public var currentCardID: NSNumber?
    @NSManaged public var totalCards: Int32

    @NSManaged public var cardSet: CardSet?
    @NSManaged public var reviewedCards: NSSet?
    @NSManaged public var remainingCards: NSSet?
}

extension StudySession {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<StudySession> {
        return NSFetchRequest<StudySession>(entityName: "StudySession")
    }
}