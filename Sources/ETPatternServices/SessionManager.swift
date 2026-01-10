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
    @Published public var currentSession: StudySession?

    // MARK: - Computed Properties
    public var currentCard: Card? {
        let cards = getCards()
        return cards.indices.contains(currentIndex) ? cards[currentIndex] : nil
    }

    // MARK: - Private Properties
    private let cardSet: CardSet
    private let modelContext: ModelContext
    private var cancellables = Set<AnyCancellable>()
    private var orderKey: String { "studyOrderMode" }

    // MARK: - Initialization
    public init(cardSet: CardSet, modelContext: ModelContext) {
        self.cardSet = cardSet
        self.modelContext = modelContext
        loadOrderMode()
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
    
    // MARK: - Session Management
    public func prepareSession() {
        let name = cardSet.name
        let fetchDescriptor = FetchDescriptor<StudySession>(
            predicate: #Predicate<StudySession> { $0.isActive && $0.cardSet?.name == name },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        if let existingSession = (try? modelContext.fetch(fetchDescriptor))?.first {
            self.currentSession = existingSession
            self.currentIndex = Int(existingSession.currentCardIndex)
            self.cardsPlayedInSession = Int(existingSession.cardsReviewed)
        } else {
            let newSession = StudySession(totalCards: Int32(cardSet.cards.count))
            newSession.cardSet = cardSet
            newSession.isActive = true
            modelContext.insert(newSession)
            self.currentSession = newSession
            self.currentIndex = 0
            self.cardsPlayedInSession = 0
        }
        
        setupCardIDs()
    }

    private func setupCardIDs() {
        let sorted = cardSet.cards.sorted { $0.id < $1.id }
        sessionCardIDs = sorted.map { Int($0.id) }
        
        if isRandomOrder {
            sessionCardIDs.shuffle()
        }
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

        if let id = currentCardID, let newIndex = sessionCardIDs.firstIndex(of: id) {
            currentIndex = newIndex
        } else {
            currentIndex = 0
        }
    }

    // MARK: - Navigation
    public func moveToNext() {
        guard !sessionCardIDs.isEmpty else { return }
        currentIndex = (currentIndex + 1) % sessionCardIDs.count
        cardsPlayedInSession += 1
        saveProgress()
    }

    public func moveToPrevious() {
        guard !sessionCardIDs.isEmpty else { return }
        currentIndex = currentIndex > 0 ? currentIndex - 1 : sessionCardIDs.count - 1
        saveProgress()
    }

    // MARK: - Progress Management
    public func saveProgress() {
        guard let session = currentSession else { return }
        session.currentCardIndex = Int32(currentIndex)
        session.cardsReviewed = Int32(cardsPlayedInSession)
        
        // Update correctCount based on review logs in this session
        session.correctCount = Int32(session.reviewLogs.filter { $0.ratingValue >= 2 }.count)
        
        try? modelContext.save()
    }
    
    public func finishSession() {
        currentSession?.isActive = false
        saveProgress()
    }

    // MARK: - Card Access
    public func getCards() -> [Card] {
        let allCards = cardSet.cards
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