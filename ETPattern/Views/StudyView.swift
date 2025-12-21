//
//  StudyView.swift
//  ETPattern
//
//  Created by admin on 25/11/2025.
//

import CoreData
import SwiftUI
import UIKit

struct StudyView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) var theme
    @EnvironmentObject private var ttsService: TTSService

    let cardSet: CardSet

    @State private var currentCardIndex = 0
    @State private var cardsDue: [Card] = []
    @State private var studySession: StudySession?
    @State private var showSessionComplete = false
    @State private var sessionStartTime: Date?
    @State private var isFlipped = false
    @State private var isRandomOrder = false
    @State private var swipeDirection: SwipeDirection? = nil
    @State private var showSwipeFeedback = false
    @State private var sessionCardList: [Card] = []  // Exclusive session list for study mode
    @State private var cardsStudiedInSession: Int = 0  // Progress counter for session

    // SessionManager-like properties
    @State private var sessionCardIDs: [Int] = []
    @State private var sessionCardsPlayed: Int = 0

    private let spacedRepetitionService = SpacedRepetitionService()

    private var progressKey: String {
        let id = cardSet.objectID.uriRepresentation().absoluteString
        return "studyProgress-\(id)"
    }
    private var sessionKey: String {
        let id = cardSet.objectID.uriRepresentation().absoluteString
        return "studySession-\(id)"
    }

    var body: some View {
        ZStack {
            theme.gradients.background
                .ignoresSafeArea()

            VStack(spacing: 8) {
                header

                Group {
                    if showSessionComplete {
                        completionView
                    } else if cardsDue.isEmpty {
                        emptyState
                    } else {
                        studySessionContent
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .zIndex(0)
            }
            .padding(.horizontal, 4)
            .safeAreaInset(edge: .bottom) {
                if !showSessionComplete && !cardsDue.isEmpty {
                    bottomControlBar
                }
            }
        }
        .onAppear {
            isRandomOrder = UserDefaults.standard.string(forKey: "cardOrderMode") == "random"
            prepareSession()
        }
        .onDisappear {
            saveProgress()
        }
    }

    private var header: some View {
        SharedHeaderView(
            title: cardSet.name ?? "Study Session",
            subtitle: "Spaced repetition learning",
            theme: theme
        )
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
                .font(theme.typography.largeTitle.weight(.bold))
                .foregroundColor(theme.colors.textPrimary)

            VStack(spacing: 18) {
                CompletionRow(title: "Cards Reviewed", value: "\(studySession?.cardsReviewed ?? 0)")
                CompletionRow(title: "Correct Answers", value: "\(studySession?.correctCount ?? 0)")
                CompletionRow(title: "Accuracy", value: accuracyText)
                if let duration = sessionDuration {
                    CompletionRow(title: "Time Spent", value: duration)
                }
            }
            .padding()
            .background(
                .ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))

            Button(action: { dismiss() }) {
                Text("Done")
                    .font(theme.typography.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.gradients.accent)
                    .foregroundColor(theme.colors.textPrimary)
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
                .foregroundColor(theme.colors.textSecondary)
            Text("No cards due for review")
                .font(theme.typography.title2.weight(.semibold))
                .foregroundColor(theme.colors.textPrimary)
            Button("Done") {
                dismiss()
            }
            .font(theme.typography.headline)
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .foregroundColor(theme.colors.textPrimary)
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var studySessionContent: some View {
        VStack(spacing: 12) {
            if currentCardIndex < cardsDue.count {
                SharedCardDisplayView(
                    frontText: cardsDue[currentCardIndex].front ?? "No front",
                    backText: formatBackText(),
                    pattern: cardsDue[currentCardIndex].front ?? "",
                    isFlipped: isFlipped,
                    currentIndex: currentCardIndex + 1,
                    totalCards: cardsDue.count,
                    cardId: Int(cardsDue[currentCardIndex].id),
                    showSwipeFeedback: showSwipeFeedback,
                    swipeDirection: swipeDirection,
                    theme: theme
                )
                .offset(x: swipeOffset)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("studyCard")
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            let horizontalAmount = value.translation.width
                            let verticalAmount = value.translation.height
                            if abs(horizontalAmount) > abs(verticalAmount)
                                && abs(horizontalAmount) > 50
                            {
                                UIImpactFeedbackGenerator.mediumImpact()
                                let direction: SwipeDirection =
                                    horizontalAmount > 0 ? .right : .left
                                animateSwipe(direction: direction)
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

            }
        }
        .onAppear {
            speakCurrentText()
        }
        .onChange(of: currentCardIndex) { _ in
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
                    .font(theme.typography.headline)
                    .foregroundColor(theme.colors.textPrimary)
                if let accuracy = currentAccuracy, accuracy > 0 {
                    Text("Accuracy \(Int(accuracy * 100))%")
                        .font(theme.typography.subheadline)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text("Today")
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
                Text("Total: \(totalCardsInSession)")
                    .font(theme.typography.headline)
                    .foregroundColor(theme.colors.textPrimary)
                Text("Remaining: \(cardsRemaining)")
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var bottomControlBar: some View {
        VStack(spacing: 0) {
            progressBarView
            mainControlsView
            // swipeInstructionsView
        }
        .background(theme.colors.surface)
        .buttonStyle(.plain)
    }

    private var progressBarView: some View {
        SharedProgressBarView(
            currentPosition: currentCardIndex + 1,
            totalCards: cardsDue.count,
            theme: theme
        )
    }

    private var mainControlsView: some View {
        HStack(spacing: 16) {
            orderToggleButton
            Spacer()
            againButton
            flipButton
            easyButton
            Spacer()
            closeButton
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .padding(.top, 8)
    }

    private var orderToggleButton: some View {
        SharedOrderToggleButton(
            isRandomOrder: isRandomOrder,
            theme: theme,
            action: {
                UIImpactFeedbackGenerator.lightImpact()
                toggleOrderMode()
            }
        )
    }

    private var againButton: some View {
        Button(action: {
            UIImpactFeedbackGenerator.mediumImpact()
            markAsAgain()
        }) {
            Image(systemName: "bookmark.fill")
                .font(theme.typography.title3)
                .foregroundColor(theme.colors.textPrimary)
                .frame(width: 44, height: 44)
                .background(theme.gradients.accent)
                .clipShape(Circle())
        }
        .accessibilityLabel("Keep it")
        .accessibilityIdentifier("Keep")
    }

    private var flipButton: some View {
        Button(action: {
            UIImpactFeedbackGenerator.lightImpact()
            withAnimation(.bouncy) {
                isFlipped.toggle()
                speakCurrentText()
            }
        }) {
            Image(systemName: "arrow.2.squarepath")
                .font(theme.typography.title)
                .foregroundColor(theme.colors.textPrimary)
                .frame(width: 60, height: 60)
                .background(theme.colors.surfaceLight)
                .clipShape(Circle())
                .shadow(color: theme.colors.highlight.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .accessibilityLabel("Flip Card")
    }

    private var easyButton: some View {
        Button(action: {
            UIImpactFeedbackGenerator.mediumImpact()
            markAsEasy()
        }) {
            Image(systemName: "trash.fill")
                .font(theme.typography.title3)
                .foregroundColor(theme.colors.textPrimary)
                .frame(width: 44, height: 44)
                .background(theme.gradients.danger)
                .clipShape(Circle())
        }
        .accessibilityLabel("Remove it")
        .accessibilityIdentifier("Remove")
    }

    private var closeButton: some View {
        SharedCloseButton(
            theme: theme,
            action: {
                UIImpactFeedbackGenerator.lightImpact()
                closeSession()
            }
        )
        .accessibilityLabel("Close Session")
    }

    private var swipeInstructionsView: some View {
        Text("Swipe left to Keep · Swipe right to Remove")
            .font(theme.typography.caption)
            .foregroundColor(theme.colors.textSecondary)
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
    }

    private struct CloseSessionButton: View {
        @Environment(\.theme) var theme
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                Image(systemName: "xmark")
                    .font(theme.typography.headline)
                    .foregroundColor(theme.colors.textPrimary)
                    .padding(10)
            }
            .background(theme.colors.surfaceMedium, in: Circle())
            .shadow(color: theme.colors.shadow, radius: 6, x: 0, y: 4)
            .accessibilityLabel("Close session")
        }
    }

    private struct CompletionRow: View {
        @Environment(\.theme) var theme
        let title: String
        let value: String

        var body: some View {
            HStack {
                Text(title)
                    .foregroundColor(theme.colors.textSecondary)
                Spacer()
                Text(value)
                    .foregroundColor(theme.colors.textPrimary)
                    .fontWeight(.semibold)
            }
        }
    }

    private var progress: Double {
        guard totalCardsInSession > 0 else { return 0 }
        return Double(currentCardNumber) / Double(totalCardsInSession)
    }

    private var totalCardsInSession: Int {
        return Int(studySession?.totalCards ?? 0)
    }

    private var cardsReviewedCount: Int {
        return Int(studySession?.cardsReviewed ?? 0)
    }

    private var currentCardNumber: Int {
        guard totalCardsInSession > 0 else { return 0 }
        let result = cardsReviewedCount + currentCardIndex + 1
        print("DEBUG: currentCardNumber calculation: cardsReviewedCount=\(cardsReviewedCount) + currentCardIndex=\(currentCardIndex) + 1 = \(result)")
        return result
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

    private var swipeOffset: CGFloat {
        guard let direction = swipeDirection, showSwipeFeedback else { return 0 }
        return direction == .right ? 300 : -300
    }

    private func animateSwipe(direction: SwipeDirection) {
        swipeDirection = direction
        withAnimation(.easeInOut(duration: 0.3)) {
            showSwipeFeedback = true
        }

        // Delay the actual action to show the feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showSwipeFeedback = false
                swipeDirection = nil
            }

            // Perform the actual action after animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if direction == .right {
                    markAsEasy()
                } else {
                    markAsAgain()
                }
            }
        }
    }

    private func getAllCards() -> [Card] {
        guard let allCards = cardSet.cards as? Set<Card> else { return [] }
        return Array(allCards)
    }

    private func createSessionList() {
        let allCards = getAllCards()
        let sorted = allCards.sorted { ($0.front ?? "") < ($1.front ?? "") }
        if isRandomOrder {
            sessionCardList = sorted.shuffled()
        } else {
            sessionCardList = sorted
        }
    }

    private func saveProgress() {
        UserDefaults.standard.set(currentCardIndex, forKey: progressKey)
    }

    private func restoreProgressIfAvailable() {
        if let savedIndex = UserDefaults.standard.object(forKey: progressKey) as? Int,
           savedIndex >= 0 && savedIndex < sessionCardIDs.count {
            currentCardIndex = savedIndex
        } else {
            currentCardIndex = 0
        }
    }

    private func prepareSession() {
        createSessionList()
        cardsDue = sessionCardList
        cardsStudiedInSession = 0

        // Load or create session card IDs
        if let saved = UserDefaults.standard.array(forKey: sessionKey) as? [Int],
           Set(saved) == Set(sessionCardList.map { Int($0.id) }) {
            sessionCardIDs = saved
        } else {
            sessionCardIDs = sessionCardList.map { Int($0.id) }
            saveSession()
        }

        // Restore progress if available
        restoreProgressIfAvailable()

        // Create Core Data session for statistics (but not for state management)
        studySession = StudySession(context: viewContext)
        studySession?.date = Date()
        studySession?.cardsReviewed = 0
        studySession?.correctCount = 0
        studySession?.cardSet = cardSet
        studySession?.remainingCards = NSSet(array: cardsDue)
        studySession?.reviewedCards = NSSet()
        studySession?.currentCardIndex = Int32(currentCardIndex)
        studySession?.totalCards = Int32(sessionCardList.count)
        studySession?.isActive = true

        sessionStartTime = Date()
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

        // Remove the card from cardsDue to keep the array in sync
        cardsDue.remove(at: currentCardIndex)

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

        // Remove the card from cardsDue to keep the array in sync
        cardsDue.remove(at: currentCardIndex)

        moveToNextCard()
    }

    private func moveToNextCard() {
        cardsStudiedInSession += 1
        // Don't increment currentCardIndex since we remove the card from cardsDue
        // currentCardIndex stays at the same position as the array shrinks
        studySession?.currentCardIndex = Int32(currentCardIndex)
        
        isFlipped = false  // Reset card to front side

        if cardsDue.isEmpty {
            endStudySession()
        } else {
            speakCurrentText()
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
            sessionCardList = []
            cardsStudiedInSession = 0
        }
    }

    private func saveStudySession() {
        try? viewContext.save()
    }

    private func shouldShuffleCards() -> Bool {
        return isRandomOrder
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
        UserDefaults.standard.set(isRandomOrder ? "random" : "sequential", forKey: "cardOrderMode")

        // Store current card ID before changing order
        let currentCardID = sessionCardIDs.indices.contains(currentCardIndex) ? sessionCardIDs[currentCardIndex] : nil

        // Apply new order mode
        if isRandomOrder {
            sessionCardIDs.shuffle()
        } else {
            sessionCardIDs.sort()
        }
        saveSession()

        // Update cardsDue to match new order
        let allCards = getAllCards()
        cardsDue = sessionCardIDs.compactMap { cardID in
            allCards.first { Int($0.id) == cardID }
        }

        // Try to find the same card in the new order
        if let currentCardID = currentCardID,
           let newIndex = sessionCardIDs.firstIndex(of: currentCardID) {
            currentCardIndex = newIndex
        } else {
            // If we can't find the card, reset to beginning
            currentCardIndex = 0
        }
    }

    private func formatBackText() -> String {
        guard let card = currentCardIndex < cardsDue.count ? cardsDue[currentCardIndex] : nil,
            let backText = card.back
        else {
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

    // MARK: - Session Management Helpers
    private func saveSession() {
        UserDefaults.standard.set(sessionCardIDs, forKey: sessionKey)
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
