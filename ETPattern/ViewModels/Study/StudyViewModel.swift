//
//  StudyViewModel.swift
//  ETPattern
//
//  Created by admin on 17/01/2026.
//

import Foundation
import SwiftData
import SwiftUI
import ETPatternModels
import ETPatternServices
import ETPatternFeatures // For Coordinators if needed, but usually Protocol based

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
    private let service: StudyServiceProtocol // Use Protocol!
    private weak var coordinator: StudyCoordinatorProtocol? // Use specific coordinator or protocol
    
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
            
            // Restart session or re-sort?
            // For now, let's just re-sort remaining if possible or just update strategy for next fetch matches
            // Ideally we might want to reload the session order.
            // Let's keep it simple: just update the property. 
            // In a real app, this might trigger a re-shuffle of `sessionCardIDs`.
            Task {
                await refreshSessionOrder()
            }
        }
    }
    
    public func moveToNext() {
        guard currentIndex < sessionCardIDs.count - 1 else {
            // End of session?
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
    
    public func handleRating(_ rating: DifficultyRating) {
        guard let card = currentCard else { return }
        
        Task {
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
                // Load existing state... (In a real app, we'd fetch the session and restore currentIndex)
                // For simplified implementation, we'll just Init a fresh list based on Strategy
                // But ideally we should respect `existingSessionID` state.
            } else {
                print("Creating new session")
                self.sessionID = try await service.createSession(for: cardSet.persistentModelID, strategy: studyStrategy)
            }
            
            // 2. Prepare Cards
            // Accessing `cardSet` managed object directly on MainActor is safe if Context is MainActor bound (View's context usually is).
            // However, for safety and MVVM+, we should probably fetch IDs.
            // But `cardSet` was passed in.
            
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
        // Simple re-sort based on new strategy if needed
        // For now, just logging
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
