import SwiftUI
import SwiftData
import Combine
import ETPatternModels
import ETPatternServices
import ETPatternCore
import ETPatternServices

@Observable @MainActor
public final class StudyViewModel {
    // MARK: - Properties
    
    // State
    public private(set) var currentCard: Card?
    public private(set) var isFlipped: Bool = false
    public private(set) var sessionCardIDs: [PersistentIdentifier] = []
    public private(set) var currentIndex: Int = 0
    public private(set) var studyStrategy: StudyStrategy = .intelligent
    public private(set) var totalCardsCount: Int = 0
    
    private var sessionID: PersistentIdentifier?
    private let cardSet: CardSet
    private let modelContext: ModelContext
    private let service: StudyServiceProtocol
    private let coordinator: StudyCoordinatorProtocol? // Strong reference to prevent premature deallocation
    
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
        self.studyStrategy = StudyStrategy(rawValue: UserDefaults.standard.string(forKey: "studyStrategy") ?? "intelligent") ?? .intelligent
    }
    
    // MARK: - Public Methods
    
    public func onAppear() async {
        await startSession()
    }
    
    public func onDisappear() {
        // Any cleanup if needed
    }
    
    public func flipCard() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isFlipped.toggle()
        }
    }
    
    public func cycleStrategy() {
        let strategies = StudyStrategy.allCases
        if let index = strategies.firstIndex(of: studyStrategy) {
            let nextIndex = (index + 1) % strategies.count
            studyStrategy = strategies[nextIndex]
            UserDefaults.standard.set(studyStrategy.rawValue, forKey: "studyStrategy")
            
            // Re-sort remaining
            Task {
                await refreshSessionOrder()
            }
        }
    }
    
    public func moveToNext() {
        guard currentIndex < sessionCardIDs.count - 1 else {
            // End of session? Behave like dismiss or loop?
            // Usually we dismiss or show summary.
            dismiss()
            return
        }
        
        withAnimation {
            isFlipped = false
            currentIndex += 1
            loadCurrentCard()
        }
        
        saveProgress()
    }
    
    public func moveToPrevious() {
        guard currentIndex > 0 else { return }
        
        withAnimation {
            isFlipped = false
            currentIndex -= 1
            loadCurrentCard()
        }
        
        saveProgress()
    }
    
    public func dismiss() {
        coordinator?.dismiss()
    }
    
    @discardableResult
    public func handleRating(_ rating: DifficultyRating) -> Task<Void, Never> {
        guard let card = currentCard else { return Task { } }
        
        return Task {
            // Update Backend/DB
            try? await service.updateCardDifficulty(
                cardID: card.persistentModelID,
                rating: rating,
                in: sessionID
            )
            
            // Move Next
            await MainActor.run {
                moveToNext()
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func startSession() async {
        // 1. Get or Create Session
        do {
            if let existingSessionID = try await service.fetchActiveSessionID(for: cardSet.persistentModelID) {
                print("Resuming session: \(existingSessionID)")
                self.sessionID = existingSessionID
            } else {
                print("Creating new session")
                self.sessionID = try await service.createSession(for: cardSet.persistentModelID, strategy: studyStrategy)
            }
            
            // 2. Prepare Cards
            self.sessionCardIDs = cardSet.cards
                .sorted { $0.nextReviewDate < $1.nextReviewDate } // Basic Intelligent Sort
                .map { $0.persistentModelID }
            
            self.totalCardsCount = sessionCardIDs.count
            
            // 3. Load First Card
            loadCurrentCard()
            
        } catch {
            print("Failed to start session: \(error)")
        }
    }
    
    private func refreshSessionOrder() async {
        print("Strategy changed to \(studyStrategy). In full impl, this would re-sort remaining cards.")
    }
    
    private func loadCurrentCard() {
        guard !sessionCardIDs.isEmpty, currentIndex < sessionCardIDs.count else {
            currentCard = nil
            return
        }
        
        let id = sessionCardIDs[currentIndex]
        // Fetch object from context
        currentCard = modelContext.model(for: id) as? Card
    }
    
    private func saveProgress() {
        guard let sID = sessionID else { return }
        let idx = currentIndex
        let count = currentIndex // approximates 'reviewed' count for sequential
        
        Task {
            try? await service.saveProgress(sessionID: sID, currentCardIndex: idx, cardsReviewed: count)
        }
    }
}
