//
//  StudyViewModel.swift
//  ETPattern
//
//  Created by admin on 28/01/2026.
//

import Foundation
import SwiftUI

@Observable @MainActor
final class StudyViewModel {
    // MARK: - State
    private(set) var currentCard: Card?
    private(set) var isFlipped = false
    private(set) var isLoading = false
    private(set) var sessionProgress: String = "0/0"
    private(set) var session: StudySession?
    
    // MARK: - Dependencies
    private let service: SessionServiceProtocol
    private let ttsService: TTSService
    private weak var coordinator: AppCoordinator?
    private let cardSet: CardSet
    
    // MARK: - Internal State
    private(set) var cards: [Card] = []
    private(set) var currentIndex: Int = 0
    
    var currentStrategy: StudyStrategy {
        session?.strategy ?? .intelligent
    }
    
    init(
        cardSet: CardSet,
        service: SessionServiceProtocol,
        ttsService: TTSService,
        coordinator: AppCoordinator?
    ) {
        self.cardSet = cardSet
        self.service = service
        self.ttsService = ttsService
        self.coordinator = coordinator
    }
    
    // MARK: - Lifecycle
    
    func startSession() async {
        isLoading = true
        do {
            // Load or create session (defaulting to Intelligent strategy)
            self.session = try await service.prepareSession(for: cardSet, strategy: .intelligent)
            
            if let session = self.session {
                // Fetch cards through the service, which accesses the session's relationships
                // Note: In SwiftData, we might need a better way to fetch sorted cards if not directly robust
                // For now assuming service handles it or we use the deck's cards
                self.cards = self.service.fetchCards(for: session)
                
                // Restore index if valid
                let savedIndex = Int(session.currentCardIndex)
                self.currentIndex = (savedIndex >= 0 && savedIndex < self.cards.count) ? savedIndex : 0
                
                updateCurrentCard()
            }
        } catch {
            print("Failed to start session: \(error)")
        }
        isLoading = false
    }
    
    func stopSession() {
        ttsService.stop()
        if let session = session {
             Task { try? await service.saveProgress(session: session) }
        }
    }
    
    // MARK: - Setup
    
    private func updateCurrentCard() {
        guard !cards.isEmpty, currentIndex < cards.count else {
            currentCard = nil
            sessionProgress = "0/0"
            return
        }
        
        currentCard = cards[currentIndex]
        sessionProgress = "\(currentIndex + 1)/\(cards.count)"
        isFlipped = false
        
        // Save progress (fire and forget)
        if let session = session {
            // Update local model first
            session.currentCardIndex = Int32(currentIndex)
            Task { try? await service.saveProgress(session: session) }
        }
        
        // Auto-read
        readCurrentCard()
    }
    
    // MARK: - Interactions
    
    func flip() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isFlipped.toggle()
        }
        readCurrentCard()
    }
    
    func rateCard(_ rating: DifficultyRating) {
        guard let card = currentCard, let session = session else { return }
        
        // Haptic Feedback
        let specificFeedback = (rating == .again) ? UIImpactFeedbackGenerator.FeedbackStyle.heavy : .medium
        UIImpactFeedbackGenerator(style: specificFeedback).impactOccurred()
        
        Task {
            try? await service.updateCardDifficulty(card: card, rating: rating, session: session)
            
            // Advance after small delay
            try? await Task.sleep(for: .milliseconds(300))
            
            await MainActor.run {
                next()
            }
        }
    }
    
    func next() {
        guard !cards.isEmpty else { return }
        currentIndex = (currentIndex + 1) % cards.count
        updateCurrentCard()
    }
    
    func previous() {
        guard !cards.isEmpty else { return }
        currentIndex = (currentIndex - 1 + cards.count) % cards.count
        updateCurrentCard()
    }
    
    func close() {
        stopSession()
        coordinator?.dismissFullScreen()
    }
    
    func cycleStrategy() {
        guard let session = session else { return }
        
        let all = StudyStrategy.allCases
        if let currentIdx = all.firstIndex(of: session.strategy) {
            let nextIdx = (currentIdx + 1) % all.count
            let newStrategy = all[nextIdx]
            
            Task {
                try? await service.updateStrategy(for: session, to: newStrategy)
                await loadCards()
            }
        }
    }
    
    // MARK: - Helpers
    
    private func loadCards() async {
        guard let session = session else { return }
        self.cards = service.fetchCards(for: session)
        updateCurrentCard()
    }
    
    private func readCurrentCard() {
        guard let card = currentCard else { return }
        let text = isFlipped ? card.back.replacingOccurrences(of: "<br>", with: "\n") : card.front
        ttsService.speak(text)
    }
}
