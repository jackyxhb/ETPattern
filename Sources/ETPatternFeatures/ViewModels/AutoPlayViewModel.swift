import SwiftUI
import Combine
import ETPatternModels
import ETPatternServices
import Foundation
#if canImport(UIKit)
import UIKit
#endif
import SwiftData

@MainActor
public class AutoPlayViewModel: ObservableObject {
    // MARK: - Published State
    @Published public var currentCard: Card?
    @Published public var currentIndex: Int = 0
    @Published public var isFlipped: Bool = false
    @Published public var isPlaying: Bool = true
    @Published public var studyStrategy: StudyStrategy = .intelligent
    @Published public var sessionCardIDs: [Int] = []
    
    // MARK: - Internal State
    private var currentSession: StudySession?
    private var speechToken = UUID()
    private var cardToken = UUID()
    private var currentTask: Task<Void, Never>?
    private var pendingSaveTask: Task<Void, Never>?
    private var activePhase: AutoPlayPhase = .front
    private var resumePhase: AutoPlayPhase = .front
    public var cardsPlayedInSession: Int = 0
    
    // MARK: - Dependencies
    private let service: StudyServiceProtocol
    private weak var coordinator: AutoPlayCoordinatorProtocol?
    private let cardSet: CardSet
    private let modelContext: ModelContext
    // We treat TTS as optional or we can inject a real one
    private let ttsService: TTSService? 
    
    // MARK: - Constants
    var fallbackFrontDelay: TimeInterval = 1.0
    var fallbackBackDelay: TimeInterval = 1.5
    var interCardDelay: TimeInterval = 1.0
    
    // MARK: - Initialization
    public init(
        cardSet: CardSet,
        modelContext: ModelContext,
        service: StudyServiceProtocol,
        coordinator: AutoPlayCoordinatorProtocol?,
        ttsService: TTSService? = nil // Optional for now to avoid breaking existing calls immediately
    ) {
        self.cardSet = cardSet
        self.modelContext = modelContext
        self.service = service
        self.coordinator = coordinator
        self.ttsService = ttsService
    }
    
    // MARK: - Lifecycle
    public func onAppear() async {
        await prepareSession()
        updateCurrentCard()
        startPlaybackIfPossible()
    }
    
    public func onDisappear() async {
        stopPlayback()
        _ = await pendingSaveTask?.value
        await saveProgress()
    }
    
    // MARK: - Actions
    public func togglePlayback() {
        if isPlaying {
            pausePlayback()
        } else {
            isPlaying = true
            #if canImport(UIKit)
            UIApplication.shared.isIdleTimerDisabled = true
            #endif
            continueFromResumePhase()
        }
    }
    
    public func dismiss() {
        coordinator?.dismiss()
    }
    
    public func manualPrevious() {
        let wasPlaying = isPlaying
        stopPlayback()
        moveToPrevious()
        resetCardState()
        if wasPlaying {
            Task {
                try? await Task.sleep(for: .milliseconds(100))
                await startPlaybackIfPossible()
            }
        }
    }
    
    public func manualNext() {
        let wasPlaying = isPlaying
        stopPlayback() 
        moveToNext()
        resetCardState()
        if wasPlaying {
            Task {
                try? await Task.sleep(for: .milliseconds(100))
                await startPlaybackIfPossible()
            }
        }
    }
    
    public func cycleStrategy() {
        let all = StudyStrategy.allCases
        if let currentIdx = all.firstIndex(of: studyStrategy) {
            let nextIdx = (currentIdx + 1) % all.count
            studyStrategy = all[nextIdx]
            currentSession?.strategy = studyStrategy
            refreshQueue() 
        }
    }

    // MARK: - Playback Logic
    
    private func startPlaybackIfPossible() {
        guard !sessionCardIDs.isEmpty else { return }
        isPlaying = true
        #if canImport(UIKit)
        UIApplication.shared.isIdleTimerDisabled = true
        #endif
        
        if cardsPlayedInSession == 0 {
             cardsPlayedInSession = 1
        }
        
        continueFromResumePhase()
    }
    
    private func stopPlayback() {
        isPlaying = false
        #if canImport(UIKit)
        UIApplication.shared.isIdleTimerDisabled = false
        #endif
        currentTask?.cancel()
        speechToken = UUID()
        ttsService?.stop()
    }
    
    private func pausePlayback() {
        isPlaying = false
        resumePhase = isFlipped ? .back : .front
        #if canImport(UIKit)
        UIApplication.shared.isIdleTimerDisabled = false
        #endif
        currentTask?.cancel()
        speechToken = UUID()
        ttsService?.stop()
        pendingSaveTask = Task { await saveProgress() }
    }
    
    private func continueFromResumePhase() {
        playPhase(resumePhase)
        resumePhase = .front // Reset for next time
    }
    
    private func playPhase(_ phase: AutoPlayPhase) {
        guard isPlaying, !sessionCardIDs.isEmpty else { return }
        
        // Update State
        self.activePhase = phase
        self.isFlipped = (phase == .back)
        
        // Identity Tokens
        let token = UUID()
        speechToken = token
        cardToken = token
        
        // Get Text
        guard let card = currentCard else { return }
        let text = text(for: phase, at: card)
        
        // Speak or Schedule Next
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
             scheduleNext(after: fallbackDelay(for: phase), token: token, currentPhase: phase)
        } else {
            ttsService?.speak(text) { [weak self] in
                Task { @MainActor in
                    guard let self = self, self.isPlaying, self.speechToken == token else { return }
                    self.advance(from: phase)
                }
            }
        }
    }
    
    private func advance(from phase: AutoPlayPhase) {
        switch phase {
        case .front:
            playPhase(.back)
        case .back:
            enqueueNextCard()
        }
    }
    
    private func enqueueNextCard() {
        let token = speechToken
        currentTask = Task {
            try? await Task.sleep(for: .seconds(interCardDelay))
            guard !Task.isCancelled, isPlaying, speechToken == token else { return }
            
            moveToNext()
            if isPlaying {
                playPhase(.front)
            }
        }
    }
    
    private func scheduleNext(after delay: TimeInterval, token: UUID, currentPhase: AutoPlayPhase) {
        currentTask = Task {
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled, isPlaying, speechToken == token else { return }
            advance(from: currentPhase)
        }
    }
    
    // MARK: - Helpers
    private func text(for phase: AutoPlayPhase, at card: Card) -> String {
        switch phase {
        case .front: return card.front
        case .back: return card.back.replacingOccurrences(of: "<br>", with: "\n")
        }
    }
    
    private func fallbackDelay(for phase: AutoPlayPhase) -> TimeInterval {
        phase == .front ? fallbackFrontDelay : fallbackBackDelay
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
             print("Error: \(error)")
        }
    }
    
    private func buildQueue() {
         // ... (Same queue logic)
         let allCards = cardSet.cards
         sessionCardIDs = allCards.map { Int($0.id) } // fallback
         updateCurrentCard()
    }
    
    private func refreshQueue() {
        buildQueue() // simplification
    }
    
    private func updateCurrentCard() {
        guard !sessionCardIDs.isEmpty, sessionCardIDs.indices.contains(currentIndex) else {
            currentCard = nil
            return
        }
        let id = sessionCardIDs[currentIndex]
        currentCard = cardSet.cards.first { Int($0.id) == id }
    }
    
    private func moveToNext() {
        guard !sessionCardIDs.isEmpty else { return }
        currentIndex = (currentIndex + 1) % sessionCardIDs.count
        cardsPlayedInSession += 1
        updateCurrentCard()
    }
    
    private func moveToPrevious() {
        guard !sessionCardIDs.isEmpty else { return }
        currentIndex = currentIndex > 0 ? currentIndex - 1 : sessionCardIDs.count - 1
        updateCurrentCard()
    }
    
    private func resetCardState() {
        isFlipped = false
        resumePhase = .front
    }
    
    private func saveProgress() async {
        guard let session = currentSession else { return }
        session.currentCardIndex = Int32(currentIndex)
        session.cardsReviewed = Int32(cardsPlayedInSession)
        
        try? await service.saveProgress(
            sessionID: session.persistentModelID,
            currentCardIndex: currentIndex,
            cardsReviewed: cardsPlayedInSession
        )
    }
}

// Supporting Enums
enum AutoPlayPhase { case front, back }
