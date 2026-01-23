import Foundation
import SwiftData
@preconcurrency import Combine

class SessionManager: ObservableObject {
    // MARK: - Published Properties
    @Published var sessionCardIDs: [Int] = []
    @Published var currentIndex: Int = 0
    @Published var currentStrategy: StudyStrategy = .intelligent
    @Published var cardsPlayedInSession: Int = 0
    @Published var currentSession: StudySession?

    // MARK: - Computed Properties
    var currentCard: Card? {
        let cards = getCards()
        return cards.indices.contains(currentIndex) ? cards[currentIndex] : nil
    }

    // MARK: - Private Properties
    private let cardSet: CardSet
    private let modelContext: ModelContext
    private var cancellables = Set<AnyCancellable>()
    private var strategyKey: String { "studyStrategy" }

    // MARK: - Initialization
    init(cardSet: CardSet, modelContext: ModelContext) {
        self.cardSet = cardSet
        self.modelContext = modelContext
        loadSavedStrategy()
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
    
    // MARK: - Session Management
    func prepareSession() {
        let name = cardSet.name
        let fetchDescriptor = FetchDescriptor<StudySession>(
            predicate: #Predicate<StudySession> { $0.isActive && $0.cardSet?.name == name },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        if let existingSession = (try? modelContext.fetch(fetchDescriptor))?.first {
            self.currentSession = existingSession
            self.currentIndex = Int(existingSession.currentCardIndex)
            self.cardsPlayedInSession = Int(existingSession.cardsReviewed)
            self.currentStrategy = existingSession.strategy
            
            if !existingSession.cardOrder.isEmpty {
                self.sessionCardIDs = existingSession.cardOrder
            } else {
                setupCardIDs()
            }
        } else {
            let newSession = StudySession(totalCards: Int32(cardSet.safeCards.count))
            newSession.cardSet = cardSet
            newSession.isActive = true
            newSession.strategy = currentStrategy
            modelContext.insert(newSession)
            self.currentSession = newSession
            self.currentIndex = 0
            self.cardsPlayedInSession = 0
            setupCardIDs()
        }
    }

    private func setupCardIDs() {
        let allCards = cardSet.safeCards
        
        switch currentStrategy {
        case .linear:
            sessionCardIDs = allCards.sorted { $0.id < $1.id }.map { Int($0.id) }
        case .shuffled:
            sessionCardIDs = allCards.map { Int($0.id) }.shuffled()
        case .intelligent:
            setupIntelligentQueue(allCards: allCards)
        }
        
        updateSessionCardOrder()
    }

    private func setupIntelligentQueue(allCards: [Card]) {
        let now = Date()
        
        // 1. Due/Overdue or Lapsed
        let dueCards = allCards.filter { ( $0.nextReviewDate <= now || $0.lapses > 0) && $0.timesReviewed > 0 }
        
        // 2. New cards
        let newCards = allCards.filter { $0.timesReviewed == 0 }
        
        // 3. The rest
        let remainingCards = allCards.filter { !dueCards.contains($0) && !newCards.contains($0) }
        
        // Combine buckets (currently randomized within buckets for best SRS results)
        sessionCardIDs = dueCards.map { Int($0.id) }.shuffled() +
                         newCards.map { Int($0.id) }.shuffled() +
                         remainingCards.map { Int($0.id) }.shuffled()
    }

    private func updateSessionCardOrder() {
        currentSession?.cardOrder = sessionCardIDs
        try? modelContext.save()
    }

    // MARK: - Strategy Management
    func cycleStrategy() {
        let all = StudyStrategy.allCases
        if let currentIdx = all.firstIndex(of: currentStrategy) {
            let nextIdx = (currentIdx + 1) % all.count
            currentStrategy = all[nextIdx]
            
            UserDefaults.standard.set(currentStrategy.rawValue, forKey: strategyKey)
            currentSession?.strategy = currentStrategy
            
            applyStrategyPreservingCurrentCard()
        }
    }

    private func applyStrategyPreservingCurrentCard() {
        guard !sessionCardIDs.isEmpty else { return }
        let currentCardID = sessionCardIDs.indices.contains(currentIndex) ? sessionCardIDs[currentIndex] : nil

        setupCardIDs()

        if let id = currentCardID, let newIndex = sessionCardIDs.firstIndex(of: id) {
            currentIndex = newIndex
        } else {
            currentIndex = 0
        }
        
        saveProgress()
    }

    // MARK: - Navigation
    func moveToNext() {
        guard !sessionCardIDs.isEmpty else { return }
        currentIndex = (currentIndex + 1) % sessionCardIDs.count
        cardsPlayedInSession += 1
        saveProgress()
    }

    func moveToPrevious() {
        guard !sessionCardIDs.isEmpty else { return }
        currentIndex = currentIndex > 0 ? currentIndex - 1 : sessionCardIDs.count - 1
        saveProgress()
    }

    // MARK: - Progress Management
    func saveProgress() {
        guard let session = currentSession else { return }
        session.currentCardIndex = Int32(currentIndex)
        session.cardsReviewed = Int32(cardsPlayedInSession)
        session.strategy = currentStrategy
        session.cardOrder = sessionCardIDs
        
        // Update correctCount based on review logs in this session
        session.correctCount = Int32(session.safeReviewLogs.filter { $0.ratingValue >= 2 }.count)
        
        try? modelContext.save()
    }
    
    func finishSession() {
        currentSession?.isActive = false
        saveProgress()
    }

    // MARK: - Card Access
    func getCards() -> [Card] {
        let allCards = cardSet.safeCards
        let cardDict = Dictionary(allCards.map { (Int($0.id), $0) }, uniquingKeysWith: { first, _ in first })
        return sessionCardIDs.compactMap { cardDict[$0] }
    }

    // MARK: - Private Methods
    private func loadSavedStrategy() {
        if let saved = UserDefaults.standard.string(forKey: strategyKey),
           let strategy = StudyStrategy(rawValue: saved) {
            currentStrategy = strategy
        }
    }
}