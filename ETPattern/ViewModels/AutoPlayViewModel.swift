//
//  AutoPlayViewModel.swift
//  ETPattern
//
//  FSM-based AutoPlay with centralized state machine
//

import Foundation
import SwiftData
import SwiftUI
import ETPatternModels
import ETPatternServices
import ETPatternServices

@Observable @MainActor
public final class AutoPlayViewModel {
    // MARK: - Public State
    
    public private(set) var currentCard: Card?
    public private(set) var isFlipped: Bool = false
    public private(set) var state: AutoPlayState = .idle
    public private(set) var sessionCardIDs: [PersistentIdentifier] = []
    public private(set) var currentIndex: Int = 0
    public private(set) var studyStrategy: StudyStrategy = .linear
    
    /// Computed property for UI binding
    public var isPlaying: Bool { state.isActive }
    
    // MARK: - Private State
    
    private var sessionID: PersistentIdentifier?
    private let cardSet: CardSet
    private let modelContext: ModelContext
    private let service: StudyServiceProtocol
    private let coordinator: AutoPlayCoordinatorProtocol?
    private var ttsService: TTSService?
    
    /// Epoch counter - incremented on every state transition to cancel pending work
    private var epoch: UInt64 = 0
    
    /// Current timer task
    private var timerTask: Task<Void, Never>?
    
    /// TTS polling task
    private var ttsPollingTask: Task<Void, Never>?
    
    // MARK: - Constants
    
    private let flipDelay: UInt64 = 600_000_000      // 600ms before flip
    private let nextDelay: UInt64 = 800_000_000      // 800ms before next card
    private let ttsPollInterval: UInt64 = 100_000_000 // 100ms poll interval
    
    // MARK: - Initialization
    
    public init(
        cardSet: CardSet,
        modelContext: ModelContext,
        service: StudyServiceProtocol,
        coordinator: AutoPlayCoordinatorProtocol?
    ) {
        self.cardSet = cardSet
        self.modelContext = modelContext
        self.service = service
        self.coordinator = coordinator
        self.studyStrategy = StudyStrategy(rawValue: UserDefaults.standard.string(forKey: "autoPlayStrategy") ?? "linear") ?? .linear
    }
    
    // MARK: - Public API
    
    public func setTTSService(_ service: TTSService) {
        self.ttsService = service
    }
    
    public func onAppear() async {
        await startSession()
        processAction(.start)
    }
    
    public func onDisappear() {
        processAction(.dismiss)
    }
    
    public func togglePlayback() {
        if state.isActive {
            processAction(.pause)
        } else {
            processAction(.resume)
        }
    }
    
    public func toggleFlip() {
        processAction(.flip)
    }
    
    public func manualNext() {
        processAction(.next)
    }
    
    public func manualPrevious() {
        processAction(.prev)
    }
    
    public func cycleStrategy() {
        let strategies = StudyStrategy.allCases
        if let index = strategies.firstIndex(of: studyStrategy) {
            let nextIndex = (index + 1) % strategies.count
            studyStrategy = strategies[nextIndex]
            UserDefaults.standard.set(studyStrategy.rawValue, forKey: "autoPlayStrategy")
            
            // Pause, refresh order, resume if was playing
            let wasActive = state.isActive
            processAction(.pause)
            
            Task { @MainActor in
                await refreshSessionOrder()
                if wasActive {
                    processAction(.resume)
                }
            }
        }
    }
    
    public func dismiss() {
        processAction(.dismiss)
    }
    
    // MARK: - FSM Core
    
    /// Central action processor - ALL state changes go through here
    private func processAction(_ action: AutoPlayAction) {
        // Increment epoch to cancel any pending async work
        epoch &+= 1
        let currentEpoch = epoch
        
        // Stop any ongoing TTS and timers
        cancelPendingWork()
        
        // Determine next state based on current state and action
        let nextState = computeNextState(from: state, action: action)
        
        // Handle side effects for state exit
        exitState(state)
        
        // Transition to new state
        state = nextState
        
        // Handle side effects for state entry
        enterState(nextState, epoch: currentEpoch, action: action)
    }
    
    /// State transition logic
    private func computeNextState(from current: AutoPlayState, action: AutoPlayAction) -> AutoPlayState {
        switch action {
        // User pause - always go to idle
        case .pause:
            return .idle
            
        // User resume - only from idle
        case .resume, .start:
            return .speakingFront
            
        // Next/Prev - load new card and start from front
        case .next, .prev:
            return .speakingFront
            
        // Flip - go to idle and toggle flip
        case .flip:
            return .idle
            
        // Dismiss - cleanup and stay idle
        case .dismiss:
            return .idle
            
        // Internal: TTS done
        case .ttsDone:
            switch current {
            case .speakingFront: return .waitingFlip
            case .speakingBack: return .waitingNext
            default: return current
            }
            
        // Internal: Timer done
        case .timerDone:
            switch current {
            case .waitingFlip: return .flipping
            case .waitingNext: return .advancingCard
            default: return current
            }
            
        // Internal: Flip animation done
        case .flipDone:
            return .speakingBack
            
        // Internal: Card loaded
        case .cardLoaded:
            return .speakingFront
        }
    }
    
    /// Side effects when leaving a state
    private func exitState(_ state: AutoPlayState) {
        // Stop TTS if leaving a speaking state
        if state.isSpeaking {
            ttsService?.stop()
        }
    }
    
    /// Side effects when entering a state
    private func enterState(_ state: AutoPlayState, epoch: UInt64, action: AutoPlayAction) {
        switch state {
        case .idle:
            // Handle dismiss specially
            if action == .dismiss {
                coordinator?.dismiss()
            }
            // Handle manual flip
            if action == .flip {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isFlipped.toggle()
                }
                // Speak current side
                speakCurrentSide()
            }
            
        case .speakingFront:
            // Handle next/prev card navigation
            if action == .next {
                nextCard()
            } else if action == .prev {
                previousCard()
            }
            // Always reset flip to front
            if isFlipped {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isFlipped = false
                }
            }
            // Start speaking front
            speakFront(epoch: epoch)
            
        case .waitingFlip:
            startTimer(duration: flipDelay, epoch: epoch)
            
        case .flipping:
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isFlipped = true
            }
            // Animation is quick, immediately transition
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard self?.epoch == epoch else { return }
                self?.processAction(.flipDone)
            }
            
        case .speakingBack:
            speakBack(epoch: epoch)
            
        case .waitingNext:
            startTimer(duration: nextDelay, epoch: epoch)
            
        case .advancingCard:
            nextCard()
            processAction(.cardLoaded)
        }
    }
    
    // MARK: - Helpers
    
    private func cancelPendingWork() {
        timerTask?.cancel()
        timerTask = nil
        ttsPollingTask?.cancel()
        ttsPollingTask = nil
        ttsService?.stop()
    }
    
    private func speakFront(epoch: UInt64) {
        guard let text = currentCard?.front, !text.isEmpty else {
            processAction(.ttsDone)
            return
        }
        speakWithCallback(text: text, epoch: epoch)
    }
    
    private func speakBack(epoch: UInt64) {
        guard let text = currentCard?.back.replacingOccurrences(of: "<br>", with: "\n"), !text.isEmpty else {
            processAction(.ttsDone)
            return
        }
        speakWithCallback(text: text, epoch: epoch)
    }
    
    private func speakCurrentSide() {
        guard let card = currentCard else { return }
        let text = isFlipped ? card.back.replacingOccurrences(of: "<br>", with: "\n") : card.front
        ttsService?.speak(text)
    }
    
    /// Speak text with callback that validates epoch before triggering state transition
    private func speakWithCallback(text: String, epoch: UInt64) {
        guard let tts = ttsService else {
            processAction(.ttsDone)
            return
        }
        
        tts.speak(text) { [weak self] in
            guard let self = self else { return }
            // Only proceed if epoch hasn't changed
            guard self.epoch == epoch else { return }
            self.processAction(.ttsDone)
        }
    }
    
    private func startTimer(duration: UInt64, epoch: UInt64) {
        timerTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: duration)
            guard self.epoch == epoch else { return }
            processAction(.timerDone)
        }
    }
    
    // MARK: - Card Management
    
    private func startSession() async {
        do {
            self.sessionID = try await service.createSession(for: cardSet.persistentModelID, strategy: studyStrategy)
            
            self.sessionCardIDs = cardSet.cards
                .sorted { $0.cardName < $1.cardName }
                .map { $0.persistentModelID }
             
            applyStrategySort()
            loadCurrentCard()
        } catch {
            print("AutoPlay Init Error: \(error)")
        }
    }
    
    private func refreshSessionOrder() async {
        guard !cardSet.cards.isEmpty else { return }
        self.sessionCardIDs = cardSet.cards.map { $0.persistentModelID }
        applyStrategySort()
        currentIndex = 0
        loadCurrentCard()
    }
    
    private func applyStrategySort() {
        switch studyStrategy {
        case .shuffled:
            sessionCardIDs.shuffle()
        case .intelligent:
            let sorted = cardSet.cards.sorted { $0.nextReviewDate < $1.nextReviewDate }
            sessionCardIDs = sorted.map { $0.persistentModelID }
        case .linear:
            let sorted = cardSet.cards.sorted { $0.cardName < $1.cardName }
            sessionCardIDs = sorted.map { $0.persistentModelID }
        }
    }
    
    private func loadCurrentCard() {
        guard !sessionCardIDs.isEmpty, currentIndex < sessionCardIDs.count else {
            currentCard = nil
            return
        }
        let id = sessionCardIDs[currentIndex]
        currentCard = modelContext.model(for: id) as? Card
        isFlipped = false
    }
    
    private func nextCard() {
        guard currentIndex < sessionCardIDs.count - 1 else {
            currentIndex = 0
            loadCurrentCard()
            return
        }
        currentIndex += 1
        loadCurrentCard()
    }
    
    private func previousCard() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        loadCurrentCard()
    }
}
