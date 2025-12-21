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
    let cardSet: CardSet

    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) var theme
    @EnvironmentObject private var ttsService: TTSService

    @StateObject private var sessionManager: SessionManager
    @State private var currentCard: Card?
    @State private var isFlipped = false
    @State private var showSwipeFeedback = false
    @State private var swipeDirection: SwipeDirection?
    @State private var isSwipeInProgress = false

    init(cardSet: CardSet) {
        self.cardSet = cardSet
        _sessionManager = StateObject(wrappedValue: SessionManager(cardSet: cardSet))
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            theme.gradients.background
                .ignoresSafeArea()

            VStack(spacing: 8) {
                header

                if sessionManager.getCards().isEmpty {
                    emptyState
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    SharedCardDisplayView(
                        frontText: currentCard?.front ?? "No front",
                        backText: (currentCard?.back ?? "No back").replacingOccurrences(of: "<br>", with: "\n"),
                        groupName: currentCard?.groupName ?? "",
                        cardName: currentCard?.cardName ?? "",
                        isFlipped: isFlipped,
                        currentIndex: sessionManager.currentIndex,
                        totalCards: sessionManager.getCards().count,
                        cardId: (currentCard?.id).flatMap { Int($0) },
                        showSwipeFeedback: showSwipeFeedback,
                        swipeDirection: swipeDirection,
                        theme: theme
                    )
                    .gesture(
                        DragGesture(minimumDistance: 50)
                            .onChanged { value in
                                if !isSwipeInProgress {
                                    let horizontalAmount = value.translation.width
                                    let verticalAmount = value.translation.height

                                    // Only trigger if horizontal movement is greater than vertical
                                    if abs(horizontalAmount) > abs(verticalAmount) && abs(horizontalAmount) > 30 {
                                        isSwipeInProgress = true
                                        swipeDirection = horizontalAmount > 0 ? .right : .left
                                        showSwipeFeedback = true
                                        UIImpactFeedbackGenerator.lightImpact()
                                    }
                                }
                            }
                            .onEnded { value in
                                if isSwipeInProgress {
                                    handleSwipe(swipeDirection!)
                                }
                                // Reset swipe state
                                showSwipeFeedback = false
                                swipeDirection = nil
                                isSwipeInProgress = false
                            }
                    )
                    .onTapGesture {
                        UIImpactFeedbackGenerator.lightImpact()
                        withAnimation(.bouncy) {
                            isFlipped.toggle()
                            speakCurrentText()
                        }
                    }
                    .accessibilityAction(named: "Flip Card") {
                        UIImpactFeedbackGenerator.lightImpact()
                        withAnimation(.bouncy) {
                            isFlipped.toggle()
                            speakCurrentText()
                        }
                    }
                    .accessibilityAction(named: "Mark as Easy") {
                        handleSwipe(.right)
                    }
                    .accessibilityAction(named: "Mark as Again") {
                        handleSwipe(.left)
                    }
                }
            }
            .padding(.horizontal, 4)
            .safeAreaInset(edge: .bottom) {
                bottomControlBar
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("English Pattern Study Session")
        .dynamicTypeSize(.large ... .accessibility5) // Support dynamic type throughout the view
        .onAppear {
            sessionManager.prepareSession()
            updateCurrentCard()
        }
        .onDisappear {
            sessionManager.saveProgress()
            ttsService.stop()
        }
        .onChange(of: sessionManager.currentIndex) { _ in
            // Reset to front side when card changes
            isFlipped = false
            // Stop any ongoing speech from previous card
            ttsService.stop()
            // Auto-read the new card
            speakCurrentText()
            // Announce card change for accessibility
            if let card = currentCard {
                UIAccessibility.post(notification: .announcement, argument: "Now showing card \(sessionManager.currentIndex + 1) of \(sessionManager.getCards().count)")
            }
        }
    }

    private var header: some View {
        SharedHeaderView(
            title: cardSet.name ?? "Study Session",
            subtitle: "Spaced repetition learning",
            theme: theme
        )
    }

    private var emptyState: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(theme.gradients.card.opacity(0.3))
                    .frame(width: 160, height: 160)

                Image(systemName: "waveform")
                    .font(.system(size: 60))
                    .foregroundColor(theme.colors.textSecondary)
            }

            VStack(spacing: 16) {
                Text("No Cards to Study")
                    .font(theme.typography.title.weight(.bold))
                    .foregroundColor(theme.colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("This deck doesn't have any cards yet")
                    .font(theme.typography.title3)
                    .foregroundColor(theme.colors.highlight)
                    .multilineTextAlignment(.center)

                Text("Add some cards to this deck or import a CSV file to start studying your patterns.")
                    .font(theme.typography.body)
                    .foregroundColor(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var bottomControlBar: some View {
        VStack(spacing: 0) {
            progressBarView
            mainControlsView
        }
        .background(theme.colors.surface)
        .buttonStyle(.plain)
    }

    private var progressBarView: some View {
        SharedProgressBarView(
            currentPosition: sessionManager.getCards().count > 0 ? sessionManager.currentIndex + 1 : 0,
            totalCards: sessionManager.getCards().count,
            theme: theme
        )
    }

    private var mainControlsView: some View {
        HStack(spacing: 16) {
            orderToggleButton
            Spacer()
            previousButton
            speakCurrentButton
            nextButton
            Spacer()
            closeButton
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .padding(.top, 8)
    }

    private var orderToggleButton: some View {
        SharedOrderToggleButton(
            isRandomOrder: sessionManager.isRandomOrder,
            theme: theme,
            action: {
                UIImpactFeedbackGenerator.lightImpact()
                sessionManager.toggleOrderMode()
            }
        )
    }

    private var previousButton: some View {
        Button(action: {
            UIImpactFeedbackGenerator.lightImpact()
            sessionManager.moveToPrevious()
            updateCurrentCard()
            sessionManager.saveProgress()
        }) {
            Image(systemName: "backward.end.fill")
                .font(theme.typography.title3)
                .foregroundColor(theme.colors.textSecondary)
                .frame(width: 44, height: 44)
                .background(theme.colors.surfaceMedium)
                .clipShape(Circle())
        }
        .disabled(sessionManager.currentIndex == 0)
        .opacity(sessionManager.currentIndex == 0 ? 0.3 : 1)
        .accessibilityLabel("Previous Card")
        .accessibilityHint(sessionManager.currentIndex == 0 ? "No previous card available" : "Go to previous card in study session")
    }

    private var speakCurrentButton: some View {
        Button(action: {
            UIImpactFeedbackGenerator.lightImpact()
            speakCurrentText()
        }) {
            Image(systemName: ttsService.isSpeaking ? "speaker.wave.2.fill" : "speaker.wave.2")
                .font(theme.typography.title3)
                .foregroundColor(theme.colors.textPrimary)
                .frame(width: 60, height: 60)
                .background(ttsService.isSpeaking ? theme.gradients.danger : theme.gradients.success)
                .clipShape(Circle())
        }
        .accessibilityLabel(ttsService.isSpeaking ? "Stop speaking" : "Speak current card")
        .accessibilityHint(ttsService.isSpeaking ? "Double tap to stop text-to-speech" : "Double tap to hear the current card content spoken aloud")
        .accessibilityValue(ttsService.isSpeaking ? "Currently speaking" : "Ready to speak")
    }

    private var nextButton: some View {
        Button(action: {
            UIImpactFeedbackGenerator.lightImpact()
            sessionManager.moveToNext()
            updateCurrentCard()
            sessionManager.saveProgress()
        }) {
            Image(systemName: "forward.end.fill")
                .font(theme.typography.title3)
                .foregroundColor(theme.colors.textPrimary)
                .frame(width: 44, height: 44)
                .background(theme.gradients.success)
                .clipShape(Circle())
        }
        .accessibilityLabel("Next Card")
        .accessibilityHint("Go to next card in study session")
    }

    private var closeButton: some View {
        SharedCloseButton(
            theme: theme,
            action: {
                UIImpactFeedbackGenerator.lightImpact()
                dismissStudy()
            }
        )
    }

    private func dismissStudy() {
        sessionManager.saveProgress()
        dismiss()
    }

    private func updateCurrentCard() {
        currentCard = sessionManager.currentCard
    }

    private func speakCurrentText() {
        guard let currentCard = currentCard else { return }
        let text = isFlipped ?
            (currentCard.back ?? "").replacingOccurrences(of: "<br>", with: "\n") :
            currentCard.front ?? ""
        ttsService.speak(text)
    }

    private func handleSwipe(_ direction: SwipeDirection) {
        guard let currentCard = currentCard else { return }

        // Update spaced repetition data
        let spacedRepetitionService = SpacedRepetitionService()
        let rating: DifficultyRating = direction == .right ? .easy : .again
        spacedRepetitionService.updateCardDifficulty(currentCard, rating: rating)

        // Save the changes
        do {
            try currentCard.managedObjectContext?.save()
        } catch {
            // Handle save error silently for now
        }

        // Provide haptic feedback
        let generator = UIImpactFeedbackGenerator(style: direction == .right ? .heavy : .rigid)
        generator.impactOccurred()

        // Move to next card after a brief delay to show feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                sessionManager.moveToNext()
                updateCurrentCard()
                sessionManager.saveProgress()
                // Reset to front side for new card
                isFlipped = false
                // Stop any ongoing speech
                ttsService.stop()
                // Auto-read the new card
                speakCurrentText()
            }
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
