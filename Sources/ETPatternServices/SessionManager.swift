import Foundation
import SwiftData
@preconcurrency import Combine
import ETPatternModels

public class SessionManager: ObservableObject {
    // MARK: - Published Properties
    @Published public var sessionCardIDs: [Int] = []
    @Published public var currentIndex: Int = 0
    @Published public var isRandomOrder: Bool = false
    @Published public var cardsPlayedInSession: Int = 0

    // MARK: - Computed Properties
    public var currentCard: Card? {
        let cards = getCards()
        return cards.indices.contains(currentIndex) ? cards[currentIndex] : nil
    }

    // MARK: - Private Properties
    private let cardSet: CardSet
    private var cancellables = Set<AnyCancellable>()
    private var progressKey: String {
        "studyProgress-\(cardSet.name)"
    }
    private var sessionKey: String {
        "studySession-\(cardSet.name)"
    }
    private var orderKey: String {
        "studyOrderMode"
    }

    // MARK: - Initialization
    public init(cardSet: CardSet) {
        self.cardSet = cardSet
        loadOrderMode()
        setupSubscriptions()
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
    
    // MARK: - Private Setup Methods
    private func setupSubscriptions() {
    }

    // MARK: - Session Management
    public func prepareSession() {
        guard sessionCardIDs.isEmpty else { return }

        let sorted = cardSet.cards.sorted { $0.id < $1.id }
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

    public func saveSession() {
        UserDefaults.standard.set(sessionCardIDs, forKey: sessionKey)
    }

    // MARK: - Order Management
    public func toggleOrderMode() {
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
    public func moveToNext() {
        guard !sessionCardIDs.isEmpty else { return }
        currentIndex = (currentIndex + 1) % sessionCardIDs.count
        cardsPlayedInSession += 1
    }

    public func moveToPrevious() {
        guard !sessionCardIDs.isEmpty else { return }
        currentIndex = currentIndex > 0 ? currentIndex - 1 : sessionCardIDs.count - 1
    }

    // MARK: - Progress Management
    public func saveProgress() {
        let progress = [
            "currentIndex": currentIndex,
            "cardsPlayedInSession": cardsPlayedInSession
        ]
        UserDefaults.standard.set(progress, forKey: progressKey)
    }

    private func restoreProgressIfAvailable() {
        if let savedProgress = UserDefaults.standard.dictionary(forKey: progressKey) as? [String: Int],
           let savedIndex = savedProgress["currentIndex"],
           let savedCardsPlayed = savedProgress["cardsPlayedInSession"],
           savedIndex >= 0 && savedIndex < sessionCardIDs.count {
            currentIndex = savedIndex
            cardsPlayedInSession = savedCardsPlayed
        }
    }

    // MARK: - Card Access
    public func getCards() -> [Card] {
        let allCards = cardSet.cards
        let cardDict = Dictionary(allCards.map { (Int($0.id), $0) }, uniquingKeysWith: { first, _ in first })
        return sessionCardIDs.compactMap { cardDict[$0] }
    }

    public func getCards(from allCards: [Card]) -> [Card] {
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