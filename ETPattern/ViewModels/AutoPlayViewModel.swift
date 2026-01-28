//
//  AutoPlayViewModel.swift
//  ETPattern
//
//  Created by admin on 28/01/2026.
//

import Foundation
import SwiftUI
import Combine

@Observable @MainActor
final class AutoPlayViewModel {
    // MARK: - API State
    private(set) var currentCard: Card?
    private(set) var isFlipped = false
    private(set) var isPlaying = true
    private(set) var session: StudySession?
    private(set) var cards: [Card] = []
    
    // Derived for UI
    var currentIndex: Int {
        guard let session = session else { return 0 }
        return Int(session.currentCardIndex)
    }
    
    var currentStrategy: StudyStrategy {
        session?.strategy ?? .intelligent
    }
    
    // MARK: - Dependencies
    private let cardSet: CardSet
    private let service: SessionServiceProtocol
    private let ttsService: TTSService
    
    // MARK: - Initialization
    init(cardSet: CardSet, service: SessionServiceProtocol, ttsService: TTSService) {
        self.cardSet = cardSet
        self.service = service
        self.ttsService = ttsService
    }
    
    // MARK: - Lifecycle
    func startSession() async {
        do {
            self.session = try await service.prepareSession(for: cardSet, strategy: .intelligent)
            await loadCards()
        } catch {
            print("Failed to start AutoPlay session: \(error)")
        }
    }
    
    func stopSession() {
        isPlaying = false
        ttsService.stop()
        saveHelper()
    }
    
    // MARK: - Actions
    
    func togglePlayback() {
        isPlaying.toggle()
        if !isPlaying {
            ttsService.stop()
            saveHelper()
        }
    }
    
    func cycleStrategy() {
        guard let session = session else { return }
        
        let all = StudyStrategy.allCases
        if let currentIdx = all.firstIndex(of: session.strategy) {
            let nextIdx = (currentIdx + 1) % all.count
            let newStrategy = all[nextIdx]
            
            Task {
                try? await service.updateStrategy(for: session, to: newStrategy)
                await loadCards() // Reload cards order
            }
        }
    }
    
    func next() {
        guard !cards.isEmpty, let session = session else { return }
        let nextIndex = (Int(session.currentCardIndex) + 1) % cards.count
        session.currentCardIndex = Int32(nextIndex)
        session.cardsReviewed += 1
        updateCurrentCard()
        isFlipped = false
        saveHelper()
    }
    
    func previous() {
        guard !cards.isEmpty, let session = session else { return }
        let current = Int(session.currentCardIndex)
        let prevIndex = current > 0 ? current - 1 : cards.count - 1
        session.currentCardIndex = Int32(prevIndex)
        updateCurrentCard()
        isFlipped = false
        saveHelper()
    }
    
    func setFlipped(_ flipped: Bool) {
        self.isFlipped = flipped
    }
    
    // MARK: - Helpers
    
    private func loadCards() async {
        guard let session = session else { return }
        self.cards = service.fetchCards(for: session)
        updateCurrentCard()
    }
    
    private func updateCurrentCard() {
        guard !cards.isEmpty, let session = session else {
            currentCard = nil
            return
        }
        let index = Int(session.currentCardIndex)
        if cards.indices.contains(index) {
            currentCard = cards[index]
        }
    }
    
    private func saveHelper() {
        guard let session = session else { return }
        Task {
            try? await service.saveProgress(session: session)
        }
    }
}
