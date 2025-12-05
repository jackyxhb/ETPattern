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
    @EnvironmentObject private var ttsService: TTSService

    let cardSet: CardSet

    @State private var currentCardIndex = 0
    @State private var cardsDue: [Card] = []
    @State private var originalCardsDue: [Card] = [] // Keep original order for sequential mode
    @State private var studySession: StudySession?
    @State private var showSessionComplete = false
    @State private var sessionStartTime: Date?
    @State private var isFlipped = false
    @State private var isRandomOrder = false
    private let spacedRepetitionService = SpacedRepetitionService()

    var body: some View {
        ZStack {
            DesignSystem.Gradients.background
                .ignoresSafeArea()

            VStack(spacing: 32) {
                header

                if showSessionComplete {
                    completionView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if cardsDue.isEmpty {
                    emptyState
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    studySessionContent
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .safeAreaInset(edge: .bottom) {
                if !showSessionComplete && !cardsDue.isEmpty {
                    actionButtonsBar
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

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(cardSet.name ?? "Study Session")
                .font(.title.bold())
                .foregroundColor(.white)
            Text("Spaced repetition learning")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
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
        VStack(spacing: 12) {
            if currentCardIndex < cardsDue.count {
                ZStack {
                    CardFace(
                        text: cardsDue[currentCardIndex].front ?? "No front",
                        pattern: "",
                        isFront: true,
                        currentIndex: cardsReviewedCount,
                        totalCards: totalCardsInSession
                    )
                    .opacity(isFlipped ? 0 : 1)
                    .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))

                    CardFace(
                        text: formatBackText(),
                        pattern: cardsDue[currentCardIndex].front ?? "",
                        isFront: false,
                        currentIndex: cardsReviewedCount,
                        totalCards: totalCardsInSession
                    )
                    .opacity(isFlipped ? 1 : 0)
                    .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, 4)
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
                .onTapGesture {
                    UIImpactFeedbackGenerator.lightImpact()
                    withAnimation(.bouncy) {
                        isFlipped.toggle()
                        speakCurrentText()
                    }
                }

                Text("Swipe left for Again · Swipe right for Easy")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .onAppear {
            speakCurrentText()
        }
        .onChange(of: currentCardIndex) { oldValue, newValue in
            // Reset to front side when card changes
            isFlipped = false
            // Stop any ongoing speech from previous card
            ttsService.stop()
            speakCurrentText()
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

    private var actionButtonsBar: some View {
        VStack(spacing: 0) {
            // Progress bar at the top of the control bar
            HStack(spacing: 12) {
                Text("\(cardsReviewedCount)/\(max(totalCardsInSession, 1))")
                    .font(.caption.bold())
                    .foregroundColor(.white.opacity(0.8))

                ProgressView(value: Double(cardsReviewedCount), total: Double(max(totalCardsInSession, 1)))
                    .tint(DesignSystem.Colors.highlight)
                    .frame(height: 4)

                if let accuracy = currentAccuracy, accuracy > 0 {
                    Text("\(Int(accuracy * 100))%")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)

            // Main control buttons - Order, Again, Flip, Easy, Close
            HStack(spacing: 12) {
                // Order toggle button
                Button(action: {
                    UIImpactFeedbackGenerator.lightImpact()
                    toggleOrderMode()
                }) {
                    Image(systemName: isRandomOrder ? "shuffle" : "arrow.up.arrow.down")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                }
                .accessibilityLabel(isRandomOrder ? "Random Order" : "Sequential Order")

                // Again button - put current card into "again" queue
                Button(action: {
                    UIImpactFeedbackGenerator.mediumImpact()
                    markAsAgain()
                }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 44, height: 44)
                        .background(DesignSystem.Gradients.danger)
                        .clipShape(Circle())
                }
                .accessibilityLabel("Again")

                // Flip button - just flip current card
                Button(action: {
                    UIImpactFeedbackGenerator.lightImpact()
                    withAnimation(.bouncy) {
                        isFlipped.toggle()
                        speakCurrentText()
                    }
                }) {
                    Image(systemName: isFlipped ? "arrow.uturn.backward" : "arrow.right")
                        .font(.title)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                        .shadow(color: DesignSystem.Colors.highlight.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .accessibilityLabel("Flip Card")

                // Easy button - current card could be passed due to that it's too easy
                Button(action: {
                    UIImpactFeedbackGenerator.mediumImpact()
                    markAsEasy()
                }) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(DesignSystem.Gradients.success)
                        .clipShape(Circle())
                }
                .accessibilityLabel("Easy")

                // Close button - close the view
                Button(action: {
                    UIImpactFeedbackGenerator.lightImpact()
                    closeSession()
                }) {
                    Image(systemName: "xmark")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Close Session")
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            .padding(.top, 8)
        }
        .background(.ultraThinMaterial)
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
            originalCardsDue = []
            return
        }

        let now = Date()
        let dueCards = cards.filter { card in
            card.nextReviewDate == nil || card.nextReviewDate! <= now
        }

        originalCardsDue = sortCardsByDueDate(Array(dueCards))
        cardsDue = originalCardsDue
    }

    private func loadAllCards() {
        if let cards = cardSet.cards as? Set<Card> {
            print("DEBUG: Found \(cards.count) cards in cardSet '\(cardSet.name ?? "unnamed")'")
            originalCardsDue = Array(cards).sorted { ($0.front ?? "") < ($1.front ?? "") }
            cardsDue = originalCardsDue
            print("DEBUG: Set cardsDue to \(cardsDue.count) cards")
        } else {
            print("DEBUG: No cards found in cardSet '\(cardSet.name ?? "unnamed")'")
            cardsDue = []
            originalCardsDue = []
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
        isFlipped = false // Reset card to front side

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

    private func resetSession() {
        if let session = studySession {
            viewContext.delete(session)
            try? viewContext.save()
            // Reset local state
            cardsDue = []
            currentCardIndex = 0
            studySession = nil
            showSessionComplete = false
            sessionStartTime = nil
            isFlipped = false
        }
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

    private func toggleOrderMode() {
        isRandomOrder.toggle()
        applyOrderModePreservingCurrentCard()
    }

    private func applyOrderModePreservingCurrentCard() {
        let currentCard = cardsDue.isEmpty ? nil : cardsDue[currentCardIndex]

        if isRandomOrder {
            cardsDue = originalCardsDue.shuffled()
        } else {
            cardsDue = originalCardsDue
        }

        // Try to find the same card in the new order
        if let currentCard = currentCard,
           let newIndex = cardsDue.firstIndex(where: { $0.objectID == currentCard.objectID }) {
            currentCardIndex = newIndex
        } else {
            // If we can't find the card, reset to beginning
            currentCardIndex = 0
            isFlipped = false
        }
    }

    private func formatBackText() -> String {
        guard let card = currentCardIndex < cardsDue.count ? cardsDue[currentCardIndex] : nil,
              let backText = card.back else {
            return "No back"
        }
        return backText.replacingOccurrences(of: "<br>", with: "\n")
    }

    private func speakCurrentText() {
        guard currentCardIndex < cardsDue.count else { return }
        let card = cardsDue[currentCardIndex]
        let textToSpeak = isFlipped ? formatBackText() : (card.front ?? "")
        ttsService.speak(textToSpeak)
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