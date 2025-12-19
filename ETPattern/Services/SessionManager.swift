//
//  SessionManager.swift
//  ETPattern
//
//  Created by admin on 20/12/2025.
//

import Foundation
import CoreData
import Combine

class SessionManager: ObservableObject {
    // MARK: - Published Properties
    @Published var sessionCardIDs: [Int] = []
    @Published var currentIndex: Int = 0
    @Published var isRandomOrder: Bool = false
    @Published var cardsPlayedInSession: Int = 0

    // MARK: - Computed Properties
    var currentCard: Card? {
        let cards = getCards()
        return cards.indices.contains(currentIndex) ? cards[currentIndex] : nil
    }

    // MARK: - Private Properties
    private let cardSet: CardSet
    private var progressKey: String {
        let id = cardSet.objectID.uriRepresentation().absoluteString
        return "autoPlayProgress-\(id)"
    }
    private var sessionKey: String {
        let id = cardSet.objectID.uriRepresentation().absoluteString
        return "autoPlaySession-\(id)"
    }
    private var orderKey: String {
        "autoPlayOrderMode"
    }

    // MARK: - Initialization
    init(cardSet: CardSet) {
        self.cardSet = cardSet
        loadOrderMode()
    }

    // MARK: - Session Management
    func prepareSession() {
        guard sessionCardIDs.isEmpty, let setCards = cardSet.cards as? Set<Card> else { return }

        let sorted = setCards.sorted { $0.id < $1.id }
        let currentIDs = sorted.map { Int($0.id) }

        // Load or create session
        if let saved = UserDefaults.standard.array(forKey: sessionKey) as? [Int],
           Set(saved) == Set(currentIDs) {
            sessionCardIDs = saved
        } else {
            sessionCardIDs = currentIDs
            saveSession()
        }

        restoreProgressIfAvailable()
    }

    func saveSession() {
        UserDefaults.standard.set(sessionCardIDs, forKey: sessionKey)
    }

    // MARK: - Order Management
    func toggleOrderMode() {
        isRandomOrder.toggle()
        UserDefaults.standard.set(isRandomOrder ? "random" : "sequential", forKey: orderKey)

        applyOrderModePreservingCurrentCard()
    }

    private func applyOrderModePreservingCurrentCard() {
        guard !sessionCardIDs.isEmpty else { return }

        let currentCardID = sessionCardIDs.indices.contains(currentIndex) ? sessionCardIDs[currentIndex] : nil

        if isRandomOrder {
            sessionCardIDs.shuffle()
        } else {
            sessionCardIDs.sort()
        }
        saveSession()

        // Try to find the same card in the new order
        if let currentCardID = currentCardID,
           let newIndex = sessionCardIDs.firstIndex(of: currentCardID) {
            currentIndex = newIndex
        } else {
            // If we can't find the card, reset to beginning
            currentIndex = 0
        }
    }

    // MARK: - Navigation
    func moveToNext() {
        guard !sessionCardIDs.isEmpty else { return }
        currentIndex = (currentIndex + 1) % sessionCardIDs.count
        cardsPlayedInSession += 1
    }

    func moveToPrevious() {
        guard !sessionCardIDs.isEmpty else { return }
        currentIndex = currentIndex > 0 ? currentIndex - 1 : sessionCardIDs.count - 1
    }

    // MARK: - Progress Management
    func saveProgress() {
        UserDefaults.standard.set(currentIndex, forKey: progressKey)
    }

    private func restoreProgressIfAvailable() {
        if let savedIndex = UserDefaults.standard.object(forKey: progressKey) as? Int,
           savedIndex >= 0 && savedIndex < sessionCardIDs.count {
            currentIndex = savedIndex
        }
    }

    // MARK: - Card Access
    func getCards() -> [Card] {
        guard let allCards = cardSet.cards as? Set<Card> else { return [] }
        let cardDict = Dictionary(allCards.map { (Int($0.id), $0) }, uniquingKeysWith: { first, _ in first })
        return sessionCardIDs.compactMap { cardDict[$0] }
    }

    func getCards(from allCards: [Card]) -> [Card] {
        let cardDict = Dictionary(allCards.map { (Int($0.id), $0) }, uniquingKeysWith: { first, _ in first })
        return sessionCardIDs.compactMap { cardDict[$0] }
    }

    // MARK: - Private Methods
    private func loadOrderMode() {
        if let savedOrder = UserDefaults.standard.string(forKey: orderKey) {
            isRandomOrder = (savedOrder == "random")
        }
    }
}