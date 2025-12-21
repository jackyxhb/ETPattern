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
        SharedEmptyStateView(
            title: "No Cards to Study",
            subtitle: "This deck doesn't have any cards yet",
            description: "Add some cards to this deck or import a CSV file to start studying your patterns.",
            icon: "waveform",
            iconColor: theme.colors.textSecondary,
            theme: theme
        )
    }

    private var bottomControlBar: some View {
        SharedBottomControlBarView(
            orderToggleAction: {
                UIImpactFeedbackGenerator.lightImpact()
                sessionManager.toggleOrderMode()
            },
            previousAction: {
                UIImpactFeedbackGenerator.lightImpact()
                sessionManager.moveToPrevious()
                updateCurrentCard()
                sessionManager.saveProgress()
            },
            nextAction: {
                UIImpactFeedbackGenerator.lightImpact()
                sessionManager.moveToNext()
                updateCurrentCard()
                sessionManager.saveProgress()
            },
            closeAction: {
                UIImpactFeedbackGenerator.lightImpact()
                dismissStudy()
            },
            isPreviousDisabled: sessionManager.currentIndex == 0,
            isRandomOrder: sessionManager.isRandomOrder,
            currentPosition: sessionManager.getCards().count > 0 ? sessionManager.currentIndex + 1 : 0,
            totalCards: sessionManager.getCards().count,
            theme: theme,
            previousHint: sessionManager.currentIndex == 0 ? "No previous card available" : "Go to previous card in study session",
            nextHint: "Go to next card in study session"
        ) {
            speakCurrentButton
        }
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
