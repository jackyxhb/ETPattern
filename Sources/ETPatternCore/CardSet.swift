//
//  CardSet.swift
//  ETPattern
//
//  Created by admin on 29/11/2025.
//

import Foundation
import CoreData

@objc(CardSet)
public class CardSet: NSManagedObject {
    @NSManaged public var name: String
    @NSManaged public var createdDate: Date
    @NSManaged public var cards: NSSet?
    @NSManaged public var studySessions: NSSet?

    public var cardsArray: [Card] {
        let set = cards as? Set<Card> ?? []
        return set.sorted { $0.id < $1.id }
    }

    public var studySessionsArray: [StudySession] {
        let set = studySessions as? Set<StudySession> ?? []
        return set.sorted { $0.date < $1.date }
    }
}

extension CardSet {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CardSet> {
        return NSFetchRequest<CardSet>(entityName: "CardSet")
    }
}