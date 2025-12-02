//
//  StudyView.swift
//  ETPattern
//
//  Created by admin on 25/11/2025.
//

import SwiftUI
import CoreData
import UIKit

struct StudyView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let cardSet: CardSet

    @State private var currentCardIndex = 0
    @State private var cardsDue: [Card] = []
    @State private var studySession: StudySession?
    @State private var showSessionComplete = false
    @State private var sessionStartTime: Date?
    private let spacedRepetitionService = SpacedRepetitionService()
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)

    var body: some View {
        VStack {
            if showSessionComplete {
                // Session complete view
                VStack(spacing: 20) {
                    Text("Session Complete!")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    VStack(spacing: 16) {
                        HStack {
                            Text("Cards Reviewed:")
                            Spacer()
                            Text("\(studySession?.cardsReviewed ?? 0)")
                                .fontWeight(.semibold)
                        }
                        
                        HStack {
                            Text("Correct Answers:")
                            Spacer()
                            Text("\(studySession?.correctCount ?? 0)")
                                .fontWeight(.semibold)
                        }
                        
                        HStack {
                            Text("Accuracy:")
                            Spacer()
                            Text(accuracyText)
                                .fontWeight(.semibold)
                        }
                        
                        if let duration = sessionDuration {
                            HStack {
                                Text("Time Spent:")
                                Spacer()
                                Text(duration)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    Button("Done") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top)
                }
                .padding()
            } else if cardsDue.isEmpty {
                Text("No cards due for review")
                    .font(.title2)
                    .foregroundColor(.secondary)
                Button("Done") {
                    dismiss()
                }
                .padding()
            } else {
                // Study session view
                VStack {
                    // Session stats header
                    HStack(alignment: .center, spacing: 16) {
                        ProgressCircle(progress: progress)
                            .frame(width: 70, height: 70)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Card \(currentCardNumber) of \(totalCardsInSession)")
                                .font(.headline)
                            if let accuracy = currentAccuracy, accuracy > 0 {
                                Text("Accuracy: \(Int(accuracy * 100))%")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Cards Today")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(totalCardsInSession)")
                                .font(.headline)
                            Text("Remaining: \(cardsRemaining)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)

                    Spacer()

                    // Card display
                    if currentCardIndex < cardsDue.count {
                        VStack {
                            CardView(card: cardsDue[currentCardIndex], currentIndex: cardsReviewedCount, totalCards: totalCardsInSession)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding()
                                .gesture(
                                    DragGesture()
                                        .onEnded { value in
                                            let horizontalAmount = value.translation.width
                                            let verticalAmount = value.translation.height
                                            
                                            // Only process horizontal swipes (more horizontal than vertical movement)
                                            if abs(horizontalAmount) > abs(verticalAmount) && abs(horizontalAmount) > 50 {
                                                feedbackGenerator.impactOccurred()
                                                if horizontalAmount > 0 {
                                                    // Swipe right = Easy
                                                    markAsEasy()
                                                } else {
                                                    // Swipe left = Again
                                                    markAsAgain()
                                                }
                                            }
                                        }
                                )
                            
                            // Swipe hint
                            Text("Swipe left for 'Again' • Swipe right for 'Easy'")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                    }

                    Spacer()

                    // Action buttons
                    HStack(spacing: 20) {
                        Button(action: markAsAgain) {
                            Text("Again")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }

                        Button(action: markAsEasy) {
                            Text("Easy")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle("Study Session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Home") {
                    dismiss()
                }
            }
        }
        .onAppear {
            loadOrCreateSession()
        }
        .onDisappear {
            try? viewContext.save()
        }
    }

    private var progress: Double {
        guard totalCardsInSession > 0 else { return 0 }
        return Double(cardsReviewedCount) / Double(totalCardsInSession)
    }

    private var totalCardsInSession: Int {
        return Int(studySession?.totalCards ?? 0)
    }

    private var cardsReviewedCount: Int {
        return Int(studySession?.cardsReviewed ?? 0)
    }

    private var currentCardNumber: Int {
        guard totalCardsInSession > 0 else { return 0 }
        let nextNumber = cardsReviewedCount + 1
        return min(nextNumber, totalCardsInSession)
    }

    private var cardsRemaining: Int {
        return max(totalCardsInSession - cardsReviewedCount, 0)
    }

    private var currentAccuracy: Double? {
        guard let cardsReviewed = studySession?.cardsReviewed, cardsReviewed > 0 else { return nil }
        guard let correctCount = studySession?.correctCount else { return nil }
        return Double(correctCount) / Double(cardsReviewed)
    }

    private var accuracyText: String {
        guard let accuracy = currentAccuracy else { return "0%" }
        return "\(Int(accuracy * 100))%"
    }

    private var sessionDuration: String? {
        guard let startTime = sessionStartTime else { return nil }
        let duration = Date().timeIntervalSince(startTime)
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func loadCardsDue() {
        guard let cards = cardSet.cards as? Set<Card> else {
            cardsDue = []
            return
        }

        let now = Date()
        let dueCards = cards.filter { card in
            card.nextReviewDate == nil || card.nextReviewDate! <= now
        }

        cardsDue = sortCardsByDueDate(Array(dueCards))
    }

    private func loadAllCards() {
        if let cards = cardSet.cards as? Set<Card> {
            print("DEBUG: Found \(cards.count) cards in cardSet '\(cardSet.name ?? "unnamed")'")
            cardsDue = Array(cards).sorted { ($0.front ?? "") < ($1.front ?? "") }
            print("DEBUG: Set cardsDue to \(cardsDue.count) cards")
        } else {
            print("DEBUG: No cards found in cardSet '\(cardSet.name ?? "unnamed")'")
            cardsDue = []
        }
    }

    private func loadOrCreateSession() {
        let fetchRequest: NSFetchRequest<StudySession> = StudySession.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "cardSet == %@ AND isActive == YES", cardSet)
        
        do {
            let existingSessions = try viewContext.fetch(fetchRequest)
            print("DEBUG: Found \(existingSessions.count) active sessions for cardSet '\(cardSet.name ?? "unnamed")'")
            if let existingSession = existingSessions.first {
                print("DEBUG: Resuming existing session")
                studySession = existingSession
                let remainingCards = existingSession.remainingCards as? Set<Card> ?? []
                cardsDue = sortCardsByDueDate(Array(remainingCards))

                if cardsDue.isEmpty {
                    endStudySession()
                    return
                }

                currentCardIndex = 0
                existingSession.currentCardIndex = 0
                sessionStartTime = Date()
                // Existing sessions resume without shuffling to preserve card order
            } else {
                print("DEBUG: Creating new session")
                loadCardsDue()
                if cardsDue.isEmpty {
                    print("DEBUG: No cards due, loading all cards")
                    loadAllCards()
                }
                if shouldShuffleCards() {
                    cardsDue.shuffle() // Randomize card order
                }
                studySession = StudySession(context: viewContext)
                studySession?.date = Date()
                studySession?.cardsReviewed = 0
                studySession?.correctCount = 0
                studySession?.cardSet = cardSet
                studySession?.remainingCards = NSSet(array: cardsDue)
                studySession?.reviewedCards = NSSet()
                studySession?.currentCardIndex = 0
                studySession?.totalCards = Int32(cardsDue.count)
                studySession?.isActive = true
                sessionStartTime = Date()
                print("DEBUG: Created new session with \(cardsDue.count) cards")
            }
        } catch {
            print("DEBUG: Error fetching sessions: \(error)")
            // Fallback to new session
            loadCardsDue()
            if cardsDue.isEmpty {
                print("DEBUG: No cards due, loading all cards")
                loadAllCards()
            }
            if shouldShuffleCards() {
                cardsDue.shuffle() // Randomize card order
            }
            studySession = StudySession(context: viewContext)
            studySession?.date = Date()
            studySession?.cardsReviewed = 0
            studySession?.correctCount = 0
            studySession?.cardSet = cardSet
            studySession?.remainingCards = NSSet(array: cardsDue)
            studySession?.reviewedCards = NSSet()
            studySession?.currentCardIndex = 0
            studySession?.totalCards = Int32(cardsDue.count)
            studySession?.isActive = true
            sessionStartTime = Date()
            print("DEBUG: Created fallback session with \(cardsDue.count) cards")
        }
    }

    private func markAsAgain() {
        guard currentCardIndex < cardsDue.count else { return }
        let card = cardsDue[currentCardIndex]

        card.recordReview(correct: false)
        spacedRepetitionService.updateCardDifficulty(card, rating: .again)
        studySession?.cardsReviewed += 1

        // Update session relationships
        if let session = studySession {
            var reviewed = session.reviewedCards as? Set<Card> ?? Set()
            reviewed.insert(card)
            session.reviewedCards = reviewed as NSSet
            
            var remaining = session.remainingCards as? Set<Card> ?? Set()
            remaining.remove(card)
            session.remainingCards = remaining as NSSet
        }

        moveToNextCard()
    }

    private func markAsEasy() {
        guard currentCardIndex < cardsDue.count else { return }
        let card = cardsDue[currentCardIndex]

        card.recordReview(correct: true)
        spacedRepetitionService.updateCardDifficulty(card, rating: .easy)
        studySession?.cardsReviewed += 1
        studySession?.correctCount += 1

        // Update session relationships
        if let session = studySession {
            var reviewed = session.reviewedCards as? Set<Card> ?? Set()
            reviewed.insert(card)
            session.reviewedCards = reviewed as NSSet
            
            var remaining = session.remainingCards as? Set<Card> ?? Set()
            remaining.remove(card)
            session.remainingCards = remaining as NSSet
        }

        moveToNextCard()
    }

    private func moveToNextCard() {
        currentCardIndex += 1
        studySession?.currentCardIndex = Int32(currentCardIndex)

        if currentCardIndex >= cardsDue.count {
            endStudySession()
        }
    }

    private func endStudySession() {
        studySession?.isActive = false
        saveStudySession()
        showSessionComplete = true
    }

    private func saveStudySession() {
        try? viewContext.save()
    }

    private func shouldShuffleCards() -> Bool {
        return UserDefaults.standard.string(forKey: "cardOrderMode") == "random"
    }

    private func sortCardsByDueDate(_ cards: [Card]) -> [Card] {
        return cards.sorted { card1, card2 in
            let date1 = card1.nextReviewDate ?? Date.distantPast
            let date2 = card2.nextReviewDate ?? Date.distantPast
            if date1 == date2 {
                return (card1.front ?? "") < (card2.front ?? "")
            }
            return date1 < date2
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let cardSet = CardSet(context: context)
    cardSet.name = "Sample Deck"

    let card = Card(context: context)
    card.front = "I think..."
    card.back = "Example 1<br>Example 2<br>Example 3<br>Example 4<br>Example 5"
    card.cardSet = cardSet

    return NavigationView {
        StudyView(cardSet: cardSet)
            .environment(\.managedObjectContext, context)
            .environmentObject(TTSService())
    }
}