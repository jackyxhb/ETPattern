//
//  StudySession.swift
//  ETPattern
//
//  Created by admin on 10/01/2026.
//

import Foundation
import SwiftData

@Model
public final class StudySession {
    public var date: Date
    public var cardsReviewed: Int32
    public var correctCount: Int32
    public var isActive: Bool
    public var currentCardIndex: Int32
    public var currentCardID: Int32?
    public var totalCards: Int32
    
    public var cardSet: CardSet?
    
    public var reviewedCards: [Card] = []
    public var remainingCards: [Card] = []

    public init(date: Date = Date(), cardsReviewed: Int32 = 0, correctCount: Int32 = 0, isActive: Bool = false, currentCardIndex: Int32 = 0, totalCards: Int32 = 0) {
        self.date = date
        self.cardsReviewed = cardsReviewed
        self.correctCount = correctCount
        self.isActive = isActive
        self.currentCardIndex = currentCardIndex
        self.totalCards = totalCards
    }
}
