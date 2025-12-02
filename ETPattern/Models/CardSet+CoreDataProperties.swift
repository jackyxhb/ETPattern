//
//  CardSet+CoreDataProperties.swift
//  ETPattern
//
//  Created by GitHub Copilot on 02/12/2025.
//

import Foundation
import CoreData

extension CardSet {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CardSet> {
        return NSFetchRequest<CardSet>(entityName: "CardSet")
    }

    @NSManaged public var name: String?
    @NSManaged public var createdDate: Date?
    @NSManaged public var cards: NSSet?
    @NSManaged public var studySessions: NSSet?
}

// MARK: Generated accessors for cards
extension CardSet {

    @objc(addCardsObject:)
    @NSManaged public func addToCards(_ value: Card)

    @objc(removeCardsObject:)
    @NSManaged public func removeFromCards(_ value: Card)

    @objc(addCards:)
    @NSManaged public func addToCards(_ values: NSSet)

    @objc(removeCards:)
    @NSManaged public func removeFromCards(_ values: NSSet)
}

// MARK: Generated accessors for studySessions
extension CardSet {

    @objc(addStudySessionsObject:)
    @NSManaged public func addToStudySessions(_ value: StudySession)

    @objc(removeStudySessionsObject:)
    @NSManaged public func removeFromStudySessions(_ value: StudySession)

    @objc(addStudySessions:)
    @NSManaged public func addToStudySessions(_ values: NSSet)

    @objc(removeStudySessions:)
    @NSManaged public func removeFromStudySessions(_ values: NSSet)
}

extension CardSet : Identifiable { }
