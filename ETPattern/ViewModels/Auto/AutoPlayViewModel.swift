//
//  AutoPlayViewModel.swift
//  ETPattern
//
//  Created by admin on 17/01/2026.
//

import Foundation
import SwiftData
import SwiftUI
import ETPatternModels
import ETPatternServices
import ETPatternFeatures

@Observable @MainActor
public final class AutoPlayViewModel {
    // MARK: - Properties
    
    public private(set) var currentCard: Card?
    public private(set) var isFlipped: Bool = false
    public private(set) var isPlaying: Bool = true // Start playing by default? View logic suggests it.
    public private(set) var sessionCardIDs: [PersistentIdentifier] = []
    public private(set) var currentIndex: Int = 0
    public private(set) var studyStrategy: StudyStrategy = .linear
    
    private var sessionID: PersistentIdentifier?
    private let cardSet: CardSet
    private let modelContext: ModelContext
    private let service: StudyServiceProtocol
    private weak var coordinator: AutoPlayCoordinatorProtocol?
    private weak var ttsService: TTSService?
    
    private var playbackTask: Task<Void, Never>?
    
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
    
    // MARK: - Public Methods
    
    public func setTTSService(_ service: TTSService) {
        self.ttsService = service
    }
    
    public func onAppear() async {
        await startSession()
    }
    
    public func onDisappear() {
        stopPlayback()
    }
    
    public func togglePlayback() {
        isPlaying.toggle()
        if isPlaying {
            startPlaybackLoop()
        } else {
            stopPlayback()
            ttsService?.stop()
        }
    }
    
    public func manualNext() {
        stopPlayback() // Pause explicit playback on manual interaction? Or keep playing? 
        isPlaying = false
        ttsService?.stop()
        nextCard()
    }
    
    public func manualPrevious() {
        stopPlayback()
        isPlaying = false
        ttsService?.stop()
        previousCard()
    }
    
    public func cycleStrategy() {
        // Just cycle through available strategies
        let strategies = StudyStrategy.allCases
        if let index = strategies.firstIndex(of: studyStrategy) {
            let nextIndex = (index + 1) % strategies.count
            studyStrategy = strategies[nextIndex]
            UserDefaults.standard.set(studyStrategy.rawValue, forKey: "autoPlayStrategy") // Different key from Study Mode
            
            // Re-sort logic if needed
            Task { @MainActor in
                await refreshSessionOrder()
            }
        }
    }
    
    public func dismiss() {
        stopPlayback()
        ttsService?.stop()
        coordinator?.dismiss()
    }
    
    // MARK: - Private Logic
    
    private func startSession() async {
        // Similar to StudyViewModel but maybe simpler session type or just listing
        // For AutoPlay, we might not track SRS strictly, mostly for listening.
        // But let's reuse session creation for tracking usage.
        
        do {
             // For AutoPlay, always create new session or fetch? 
             // Let's just create one for logging.
             self.sessionID = try await service.createSession(for: cardSet.persistentModelID, strategy: studyStrategy)
            
            self.sessionCardIDs = cardSet.cards
                .sorted { $0.cardName < $1.cardName } // Default sequential
                .map { $0.persistentModelID }
             
             // Apply Strategy sort
             applyStrategySort()
            
            loadCurrentCard()
            
            if isPlaying {
                startPlaybackLoop()
            }
        } catch {
            print("AutoPlay Init Error: \(error)")
        }
    }
    
    private func refreshSessionOrder() async {
         // Re-fetch card IDs
         guard !cardSet.cards.isEmpty else { return }
         self.sessionCardIDs = cardSet.cards.map { $0.persistentModelID }
         applyStrategySort()
         
         // Reset index if out of bounds (shouldn't be, same count)
         currentIndex = 0
         loadCurrentCard()
    }
    
    private func applyStrategySort() {
        // This relies on having the card objects loaded. 
        // Logic simplified for demo. Real app would do sophisticated sorting.
        if studyStrategy == .shuffled {
            sessionCardIDs.shuffle()
        } else {
            // Sequential / Intelligent (default to name sort for auto play usually)
            // But let's try to respect 'nextReview' for intelligent
             let cards = cardSet.cards
             if studyStrategy == .intelligent {
                 let sorted = cards.sorted { $0.nextReviewDate < $1.nextReviewDate }
                 sessionCardIDs = sorted.map { $0.persistentModelID }
             } else {
                 // Sequential / Linear
                 let sorted = cards.sorted { $0.cardName < $1.cardName }
                 sessionCardIDs = sorted.map { $0.persistentModelID }
             }
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
            // Loop? or Stop?
            // Let's loop for AutoPlay
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
    
    // MARK: - Playback Loop
    
    private func stopPlayback() {
        playbackTask?.cancel()
        playbackTask = nil
    }
    
    private func startPlaybackLoop() {
        stopPlayback()
        playbackTask = Task { @MainActor in
            while isPlaying && !Task.isCancelled {
                // 1. Speak Front
                await speak(text: currentCard?.front)
                
                // Wait delay
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1s gap
                
                if Task.isCancelled { break }
                
                // Flip
                withAnimation {
                    isFlipped = true
                }
                
                // 2. Speak Back
                let backText = currentCard?.back.replacingOccurrences(of: "<br>", with: "\n")
                await speak(text: backText)
                
                // Wait delay
                try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5s gap
                
                if Task.isCancelled { break }
                
                // Next
                withAnimation {
                    nextCard()
                }
            }
        }
    }
    
    private func speak(text: String?) async {
        guard let text = text, !text.isEmpty, let tts = ttsService else { return }
        
        tts.speak(text)
        
        // Wait for speaking to finish
        // Since TTS is often delegate/callback based and our service is simple,
        // we might have to poll `isSpeaking` or just approximate with length.
        
        // Better: Wait loop for `isSpeaking`
        while tts.isSpeaking {
             try? await Task.sleep(nanoseconds: 200_000_000) // 0.2s check
        }
    }
}
