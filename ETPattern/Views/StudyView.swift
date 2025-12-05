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

    var body: some View {
        ZStack(alignment: .topTrailing) {
            DesignSystem.Gradients.background
                .ignoresSafeArea()

            content
                .padding(.horizontal)
                .padding(.top, 32)

            CloseSessionButton(action: closeSession)
                .padding(.top, 8)
                .padding(.trailing, 12)
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

    @ViewBuilder
    private var content: some View {
        if showSessionComplete {
            completionView
        } else if cardsDue.isEmpty {
            emptyState
        } else {
            studySessionContent
        }
    }

    private var completionView: some View {
        VStack(spacing: 24) {
            Text("Session Complete")
                .font(.largeTitle.bold())
                .foregroundColor(.white)

            VStack(spacing: 18) {
                CompletionRow(title: "Cards Reviewed", value: "\(studySession?.cardsReviewed ?? 0)")
                CompletionRow(title: "Correct Answers", value: "\(studySession?.correctCount ?? 0)")
                CompletionRow(title: "Accuracy", value: accuracyText)
                if let duration = sessionDuration {
                    CompletionRow(title: "Time Spent", value: duration)
                }
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))

            Button(action: { dismiss() }) {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(DesignSystem.Gradients.accent)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 60)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.largeTitle)
                .foregroundColor(.white.opacity(0.7))
            Text("No cards due for review")
                .font(.title2.weight(.semibold))
                .foregroundColor(.white)
            Button("Done") {
                dismiss()
            }
            .font(.headline)
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .foregroundColor(.white)
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var studySessionContent: some View {
        VStack(spacing: 24) {
            statsHeader

            if currentCardIndex < cardsDue.count {
                VStack(spacing: 12) {
                    CardView(card: cardsDue[currentCardIndex], currentIndex: cardsReviewedCount, totalCards: totalCardsInSession)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .gesture(
                            DragGesture()
                                .onEnded { value in
                                    let horizontalAmount = value.translation.width
                                    let verticalAmount = value.translation.height
                                    if abs(horizontalAmount) > abs(verticalAmount) && abs(horizontalAmount) > 50 {
                                        UIImpactFeedbackGenerator.mediumImpact()
                                        if horizontalAmount > 0 {
                                            markAsEasy()
                                        } else {
                                            markAsAgain()
                                        }
                                    }
                                }
                        )

                    Text("Swipe left for Again · Swipe right for Easy")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }

            actionButtons
        }
    }

    private var statsHeader: some View {
        HStack(spacing: 16) {
            ProgressCircle(progress: progress)
                .frame(width: 70, height: 70)

            VStack(alignment: .leading, spacing: 6) {
                Text("Card \(currentCardNumber) of \(max(totalCardsInSession, 1))")
                    .font(.headline)
                    .foregroundColor(.white)
                if let accuracy = currentAccuracy, accuracy > 0 {
                    Text("Accuracy \(Int(accuracy * 100))%")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text("Today")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                Text("Total: \(totalCardsInSession)")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("Remaining: \(cardsRemaining)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var actionButtons: some View {
        HStack(spacing: 16) {
            Button(action: {
                UIImpactFeedbackGenerator.mediumImpact()
                markAsAgain()
            }) {
                Label("Again", systemImage: "arrow.counterclockwise")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(DesignSystem.Gradients.danger)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .buttonStyle(.plain)

            Button(action: {
                UIImpactFeedbackGenerator.mediumImpact()
                markAsEasy()
            }) {
                Label("Easy", systemImage: "checkmark.circle")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(DesignSystem.Gradients.success)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private struct CloseSessionButton: View {
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(10)
            }
            .background(Color.white.opacity(0.2), in: Circle())
            .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 4)
            .accessibilityLabel("Close session")
        }
    }

    private struct CompletionRow: View {
        let title: String
        let value: String

        var body: some View {
            HStack {
                Text(title)
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Text(value)
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
            }
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

    private func closeSession() {
        studySession?.isActive = false
        saveStudySession()
        dismiss()
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