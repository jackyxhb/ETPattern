import SwiftUI
import SwiftData
import Combine
import ETPatternModels
import ETPatternServices
import ETPatternCore

@MainActor
public class StudyViewModel: ObservableObject {
    // MARK: - Published State
    @Published public var currentCard: Card?
    @Published public var currentIndex: Int = 0
    @Published public var isFlipped: Bool = false
    @Published public var studyStrategy: StudyStrategy = .intelligent
    @Published public var sessionCardIDs: [Int] = [] // IDs of cards in current session
    
    // MARK: - Dependencies
    private let service: StudyServiceProtocol
    private weak var coordinator: StudyCoordinatorProtocol?
    private let modelContext: ModelContext
    private let cardSet: CardSet
    
    // MARK: - Internal State
    private var currentSession: StudySession?
    private var cardsPlayedInSession: Int = 0
    
    // MARK: - Initialization
    public init(
        cardSet: CardSet,
        modelContext: ModelContext,
        service: StudyServiceProtocol,
        coordinator: StudyCoordinatorProtocol?
    ) {
        self.cardSet = cardSet
        self.modelContext = modelContext
        self.service = service
        self.coordinator = coordinator
        
        loadSavedStrategy()
    }
    
    // MARK: - Lifecycle
    public func onAppear() async {
        await prepareSession()
        updateCurrentCard()
    }
    
    public func onDisappear() async {
        await saveProgress()
    }
    
    // MARK: - User Actions
    public func flipCard() {
        withAnimation(.bouncy) {
            isFlipped.toggle()
        }
    }
    
    @discardableResult
    public func handleRating(_ rating: DifficultyRating) -> Task<Void, Never> {
        guard let card = currentCard else { return Task { } }
        let cardID = card.persistentModelID
        let sessionID = currentSession?.persistentModelID
        
        let serviceTask = Task {
            try? await service.updateCardDifficulty(cardID: cardID, rating: rating, in: sessionID)
        }
        
        let moveTask = moveToNext()
        
        return Task {
            await serviceTask.value
            await moveTask?.value
        }
    }
    
    @discardableResult
    public func moveToNext() -> Task<Void, Never>? {
        guard !sessionCardIDs.isEmpty else { return nil }
        currentIndex = (currentIndex + 1) % sessionCardIDs.count
        cardsPlayedInSession += 1
        isFlipped = false
        updateCurrentCard()
        return Task { await saveProgress() }
    }
    
    @discardableResult
    public func moveToPrevious() -> Task<Void, Never>? {
        guard !sessionCardIDs.isEmpty else { return nil }
        currentIndex = currentIndex > 0 ? currentIndex - 1 : sessionCardIDs.count - 1
        isFlipped = false
        updateCurrentCard()
        return Task { await saveProgress() }
    }
    
    public func cycleStrategy() {
        let all = StudyStrategy.allCases
        if let currentIdx = all.firstIndex(of: studyStrategy) {
            let nextIdx = (currentIdx + 1) % all.count
            studyStrategy = all[nextIdx]
            
            UserDefaults.standard.set(studyStrategy.rawValue, forKey: "studyStrategy")
            currentSession?.strategy = studyStrategy
            
            // Re-shuffle preserving current card logic would go here
            refreshQueue()
        }
    }
    
    public func dismiss() {
        coordinator?.dismiss()
    }
    
    // MARK: - Private Helpers
    private func updateCurrentCard() {
        guard !sessionCardIDs.isEmpty, sessionCardIDs.indices.contains(currentIndex) else {
            currentCard = nil
            return
        }
        let id = sessionCardIDs[currentIndex]
        // Resolve ID to Card from MainContext
        // We use the local cardSet array for speed
        currentCard = cardSet.cards.first { Int($0.id) == id }
    }
    
    private func prepareSession() async {
        do {
            var sessionID: PersistentIdentifier?
            if let existingID = try await service.fetchActiveSessionID(for: cardSet.persistentModelID) {
                sessionID = existingID
            } else {
                 sessionID = try await service.createSession(for: cardSet.persistentModelID, strategy: studyStrategy)
            }
            
            guard let id = sessionID, let session = modelContext.model(for: id) as? StudySession else { return }
            self.currentSession = session
            
            // Check if it's a fresh session or existing
            // If it has history, use it
            if !session.cardOrder.isEmpty {
                 self.currentIndex = Int(session.currentCardIndex)
                 self.cardsPlayedInSession = Int(session.cardsReviewed)
                 self.studyStrategy = session.strategy
                 self.sessionCardIDs = session.cardOrder
            } else {
                 self.currentIndex = 0
                 self.cardsPlayedInSession = 0
                 buildQueue()
            }
        } catch {
            print("Error preparing session: \(error)")
        }
    }
    
    private func buildQueue() {
        let allCards = cardSet.cards
        switch studyStrategy {
        case .linear:
            sessionCardIDs = allCards.sorted { $0.id < $1.id }.map { Int($0.id) }
        case .shuffled:
            sessionCardIDs = allCards.map { Int($0.id) }.shuffled()
        case .intelligent:
            setupIntelligentQueue(allCards: allCards)
        }
        
        // Update session model locally
        currentSession?.cardOrder = sessionCardIDs
    }
    
    private func refreshQueue() {
        buildQueue()
    }
    
    private func setupIntelligentQueue(allCards: [Card]) {
        let now = Date()
        let dueCards = allCards.filter { ( $0.nextReviewDate <= now || $0.lapses > 0) && $0.timesReviewed > 0 }
        let newCards = allCards.filter { $0.timesReviewed == 0 }
        let remainingCards = allCards.filter { !dueCards.contains($0) && !newCards.contains($0) }
        
        sessionCardIDs = dueCards.map { Int($0.id) }.shuffled() +
                         newCards.map { Int($0.id) }.shuffled() +
                         remainingCards.map { Int($0.id) }.shuffled()
    }
    
    private func saveProgress() async {
        guard let session = currentSession else { return }
        session.currentCardIndex = Int32(currentIndex)
        session.cardsReviewed = Int32(cardsPlayedInSession)
        
        // Save via Service
        try? await service.saveProgress(
            sessionID: session.persistentModelID,
            currentCardIndex: currentIndex,
            cardsReviewed: cardsPlayedInSession
        )
    }
    
    private func loadSavedStrategy() {
        if let saved = UserDefaults.standard.string(forKey: "studyStrategy"),
           let strategy = StudyStrategy(rawValue: saved) {
            studyStrategy = strategy
        }
    }
    
    // Helper to get total cards count
    var totalCardsCount: Int {
        sessionCardIDs.count
    }
}
