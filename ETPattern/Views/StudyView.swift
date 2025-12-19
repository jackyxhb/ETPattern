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

    private let spacedRepetitionService = SpacedRepetitionService()

    enum SwipeDirection {
        case left, right
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
            loadOrCreateSession()
        }
        .onDisappear {
            try? viewContext.save()
        }
    }

    private var header: some View {
         HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(cardSet.name ?? "Study Session")
                    .font(theme.typography.title.weight(.bold))
                    .foregroundColor(theme.colors.textPrimary)
                Text("Spaced repetition learning")
                    .font(theme.typography.subheadline)
                    .foregroundColor(theme.colors.textSecondary)
            }
            Spacer()
        }
        .padding(.horizontal, 4)
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

                    // Swipe feedback overlay
                    if showSwipeFeedback, let direction = swipeDirection {
                        ZStack {
                            theme.colors.surfaceLight
                            VStack {
                                Image(
                                    systemName: direction == .right
                                        ? "checkmark.circle.fill"
                                        : "arrow.counterclockwise.circle.fill"
                                )
                                .font(.system(size: 60))
                                .foregroundColor(
                                    direction == .right ? theme.colors.success : theme.colors.danger
                                )
                                Text(direction == .right ? "Easy" : "Again")
                                    .font(theme.typography.title.weight(.bold))
                                    .foregroundColor(theme.colors.textPrimary)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .transition(.opacity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, 4)
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
        HStack(spacing: 12) {
            let currentPosition =
                sessionCardList.count > 0
                ? ((cardsStudiedInSession % sessionCardList.count) + 1) : 0
            Text("\(currentPosition)/\(sessionCardList.count)")
                .font(theme.typography.caption.weight(.bold))
                .foregroundColor(theme.colors.textPrimary.opacity(0.8))

            ProgressView(value: progress)
                .tint(theme.colors.highlight)
                .frame(height: 4)

            percentageText(currentPosition: currentPosition)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private func percentageText(currentPosition: Int) -> some View {
        Text(sessionCardList.count > 0 ? "\(Int((Double(currentPosition) / Double(sessionCardList.count)) * 100))%" : "0%")
            .font(theme.typography.caption2)
            .foregroundColor(theme.colors.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(theme.colors.surfaceMedium)
            .clipShape(Capsule())
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
        Button(action: {
            UIImpactFeedbackGenerator.lightImpact()
            toggleOrderMode()
        }) {
            Image(systemName: isRandomOrder ? "shuffle" : "arrow.up.arrow.down")
                .font(theme.typography.title3)
                .foregroundColor(theme.colors.textPrimary)
                .frame(width: 44, height: 44)
                .background(theme.colors.surfaceLight)
                .clipShape(Circle())
        }
        .accessibilityLabel(isRandomOrder ? "Random Order" : "Sequential Order")
    }

    private var againButton: some View {
        Button(action: {
            UIImpactFeedbackGenerator.mediumImpact()
            markAsAgain()
        }) {
            Image(systemName: "arrow.counterclockwise")
                .font(theme.typography.title3)
                .foregroundColor(theme.colors.textSecondary)
                .frame(width: 44, height: 44)
                .background(theme.gradients.danger)
                .clipShape(Circle())
        }
        .accessibilityLabel("Again")
        .accessibilityIdentifier("Again")
    }

    private var flipButton: some View {
        Button(action: {
            UIImpactFeedbackGenerator.lightImpact()
            withAnimation(.bouncy) {
                isFlipped.toggle()
                speakCurrentText()
            }
        }) {
            Image(systemName: isFlipped ? "arrow.uturn.backward" : "arrow.right")
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
            Image(systemName: "checkmark.circle.fill")
                .font(theme.typography.title3)
                .foregroundColor(theme.colors.textPrimary)
                .frame(width: 44, height: 44)
                .background(theme.gradients.success)
                .clipShape(Circle())
        }
        .accessibilityLabel("Easy")
        .accessibilityIdentifier("Easy")
    }

    private var closeButton: some View {
        Button(action: {
            UIImpactFeedbackGenerator.lightImpact()
            closeSession()
        }) {
            Image(systemName: "xmark")
                .font(theme.typography.title3)
                .foregroundColor(theme.colors.textPrimary)
                .frame(width: 44, height: 44)
                .background(theme.colors.surfaceLight)
                .clipShape(Circle())
        }
        .accessibilityLabel("Close Session")
    }

    private var swipeInstructionsView: some View {
        Text("Swipe left for Again · Swipe right for Easy")
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
        guard sessionCardList.count > 0 else { return 0 }
        let currentPosition = (cardsStudiedInSession % sessionCardList.count) + 1
        return Double(currentPosition) / Double(sessionCardList.count)
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

    private func createSessionList() {
        guard let setCards = cardSet.cards as? Set<Card> else {
            sessionCardList = []
            return
        }

        let sorted = setCards.sorted { ($0.front ?? "") < ($1.front ?? "") }
        if isRandomOrder {
            sessionCardList = sorted.shuffled()
        } else {
            sessionCardList = sorted
        }
    }

    private func loadOrCreateSession() {
        let fetchRequest: NSFetchRequest<StudySession> = StudySession.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "cardSet == %@ AND isActive == YES", cardSet)

        do {
            let existingSessions = try viewContext.fetch(fetchRequest)
            print(
                "DEBUG: Found \(existingSessions.count) active sessions for cardSet '\(cardSet.name ?? "unnamed")'"
            )
            if let existingSession = existingSessions.first {
                print("DEBUG: Resuming existing session")
                studySession = existingSession
                let remainingCards = existingSession.remainingCards as? Set<Card> ?? []
                cardsDue = sortCardsByDueDate(Array(remainingCards))

                if cardsDue.isEmpty {
                    endStudySession()
                    return
                }

                // Recreate session list in the same order as when session was created
                createSessionList()
                cardsStudiedInSession = Int(existingSession.cardsReviewed)
                currentCardIndex = 0
                existingSession.currentCardIndex = 0
                sessionStartTime = Date()
                // Existing sessions resume without changing order to preserve card sequence
            } else {
                print("DEBUG: Creating new session")
                createSessionList()
                cardsDue = sessionCardList  // Start with all cards in session
                cardsStudiedInSession = 0

                studySession = StudySession(context: viewContext)
                studySession?.date = Date()
                studySession?.cardsReviewed = 0
                studySession?.correctCount = 0
                studySession?.cardSet = cardSet
                studySession?.remainingCards = NSSet(array: cardsDue)
                studySession?.reviewedCards = NSSet()
                studySession?.currentCardIndex = 0
                studySession?.totalCards = Int32(sessionCardList.count)
                studySession?.isActive = true
                sessionStartTime = Date()
                print("DEBUG: Created new session with \(cardsDue.count) cards")
            }
        } catch {
            print("DEBUG: Error fetching sessions: \(error)")
            // Fallback to new session
            createSessionList()
            cardsDue = sessionCardList
            cardsStudiedInSession = 0
            studySession = StudySession(context: viewContext)
            studySession?.date = Date()
            studySession?.cardsReviewed = 0
            studySession?.correctCount = 0
            studySession?.cardSet = cardSet
            studySession?.remainingCards = NSSet(array: cardsDue)
            studySession?.reviewedCards = NSSet()
            studySession?.currentCardIndex = 0
            studySession?.totalCards = Int32(sessionCardList.count)
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
        cardsStudiedInSession += 1
        currentCardIndex += 1
        studySession?.currentCardIndex = Int32(currentCardIndex)
        isFlipped = false  // Reset card to front side

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
        applyOrderModePreservingCurrentCard()
    }

    private func applyOrderModePreservingCurrentCard() {
        let currentCard = cardsDue.isEmpty ? nil : cardsDue[currentCardIndex]

        // Recreate session list with new order
        createSessionList()

        // Filter session list to only include remaining cards
        let remainingCardIDs = Set(cardsDue.map { $0.objectID })
        cardsDue = sessionCardList.filter { remainingCardIDs.contains($0.objectID) }

        // Try to find the same card in the new order
        if let currentCard = currentCard,
            let newIndex = cardsDue.firstIndex(where: { $0.objectID == currentCard.objectID })
        {
            currentCardIndex = newIndex
        } else {
            // If we can't find the card, reset to beginning
            currentCardIndex = 0
            isFlipped = false
        }

        // Reset session progress when order changes
        cardsStudiedInSession = Int(studySession?.cardsReviewed ?? 0)
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
