import SwiftUI
import SwiftData
import UIKit
import os.log
import ETPatternModels
import ETPatternServices

struct StudyView: View {
    let cardSet: CardSet

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.theme) var theme
    @EnvironmentObject private var ttsService: TTSService

    @StateObject private var sessionManager: SessionManager
    private let modelContext: ModelContext
    
    private let logger = Logger(subsystem: "com.jack.ETPattern", category: "StudyView")
    
    @State private var currentCard: Card?
    @State private var isFlipped = false
    @State private var showSwipeFeedback = false
    @State private var swipeDirection: SwipeDirection?
    @State private var isSwipeInProgress = false
    @State private var swipeTask: Task<Void, Never>?

    init(cardSet: CardSet, modelContext: ModelContext) {
        self.cardSet = cardSet
        self.modelContext = modelContext
        _sessionManager = StateObject(wrappedValue: SessionManager(cardSet: cardSet, modelContext: modelContext))
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            theme.gradients.background
                .ignoresSafeArea()

            VStack(spacing: theme.metrics.studyViewSpacing) {
                header

                if sessionManager.getCards().isEmpty {
                    emptyState
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onAppear {
                            print("StudyView: No cards available")
                        }
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
                    .onAppear {
                        logger.info("StudyView: Rendering SharedCardDisplayView with front: \((currentCard?.front.prefix(50)) ?? "nil"), back: \((currentCard?.back.prefix(50)) ?? "nil")")
                    }
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
                        handleRating(.easy)
                    }
                    .accessibilityAction(named: "Mark as Again") {
                        handleRating(.again)
                    }
                }
            }
            .onAppear {
                print("StudyView: Card count = \(sessionManager.getCards().count)")
            }
            .padding(.horizontal, theme.metrics.studyViewHorizontalPadding)
            .safeAreaInset(edge: .bottom) {
                if isFlipped {
                    ratingToolbar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    bottomControlBar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
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
        .onChange(of: sessionManager.currentIndex) { _, _ in
            // Reset to front side when card changes
            isFlipped = false
            // Stop any ongoing speech from previous card
            ttsService.stop()
            // Auto-read the new card
            speakCurrentText()
            // Announce card change for accessibility
            if let _ = currentCard {
                UIAccessibility.post(notification: .announcement, argument: "Now showing card \(sessionManager.currentIndex + 1) of \(sessionManager.getCards().count)")
            }
        }
    }

    private var header: some View {
        SharedHeaderView(
            title: cardSet.name,
            subtitle: "Spaced repetition learning",
            theme: theme
        )
    }

    private var emptyState: some View {
        SharedEmptyStateView(
            title: NSLocalizedString("no_cards_title", comment: "Title for empty cards state"),
            subtitle: NSLocalizedString("no_cards_subtitle", comment: "Subtitle for empty cards state"),
            description: NSLocalizedString("no_cards_description", comment: "Description for empty cards state"),
            icon: "waveform",
            iconColor: theme.colors.textSecondary,
            theme: theme
        )
    }

    private var bottomControlBar: some View {
        SharedBottomControlBarView(
            strategyToggleAction: {
                UIImpactFeedbackGenerator.lightImpact()
                sessionManager.cycleStrategy()
                updateCurrentCard()
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
            strategy: sessionManager.currentStrategy,
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
                .font(theme.metrics.title3)
                .foregroundColor(theme.colors.textPrimary)
                .frame(width: theme.metrics.studySpeakButtonSize, height: theme.metrics.studySpeakButtonSize)
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
            currentCard.back.replacingOccurrences(of: "<br>", with: "\n") :
            currentCard.front
        ttsService.speak(text)
    }

    private var ratingToolbar: some View {
        HStack(spacing: theme.metrics.actionBarButtonSpacing) {
            RatingButton(title: "Again", color: theme.colors.danger, action: { handleRating(.again) })
            RatingButton(title: "Hard", color: theme.colors.warning, action: { handleRating(.hard) })
            RatingButton(title: "Good", color: theme.colors.success, action: { handleRating(.good) })
            RatingButton(title: "Easy", color: theme.colors.highlight, action: { handleRating(.easy) })
        }
        .padding(.horizontal, theme.metrics.actionBarHorizontalPadding)
        .padding(.vertical, theme.metrics.actionBarVerticalPadding)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: theme.metrics.actionBarCornerRadius, style: .continuous))
        .padding(.horizontal, theme.metrics.actionBarContainerHorizontalPadding)
    }

    private struct RatingButton: View {
        let title: String
        let color: Color
        let action: () -> Void
        @Environment(\.theme) var theme

        var body: some View {
            Button(action: action) {
                Text(title)
                    .font(theme.metrics.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, theme.metrics.actionButtonVerticalPadding)
                    .background(color.opacity(0.8))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: theme.metrics.actionButtonCornerRadius, style: .continuous))
            }
        }
    }

    private func handleRating(_ rating: DifficultyRating) {
        guard let currentCard = currentCard else { return }

        // Cancel any existing swipe task
        swipeTask?.cancel()

        // Update spaced repetition data
        let spacedRepetitionService = SpacedRepetitionService()
        spacedRepetitionService.updateCardDifficulty(currentCard, rating: rating, in: sessionManager.currentSession)

        // Provide haptic feedback
        let generator = UIImpactFeedbackGenerator(style: rating == .again ? .heavy : .medium)
        generator.impactOccurred()

        // Move to next card after a brief delay
        swipeTask = Task {
            do {
                try await Task.sleep(for: .milliseconds(400))
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    withAnimation {
                        sessionManager.moveToNext()
                        updateCurrentCard()
                        // Reset to front side for new card
                        isFlipped = false
                        // Stop any ongoing speech
                        ttsService.stop()
                        // Auto-read the new card
                        speakCurrentText()
                    }
                }
            } catch {}
        }
    }

    private func handleSwipe(_ direction: SwipeDirection) {
        if isFlipped {
            handleRating(direction == .right ? .good : .again)
        } else {
            // Just flip the card on swipe if not flipped? Or maybe same as tap.
            withAnimation(.bouncy) {
                isFlipped = true
                speakCurrentText()
            }
        }
    }
}

#Preview {
    NavigationView {
        StudyView(cardSet: previewCardSet, modelContext: PersistenceController.preview.container.mainContext)
            .modelContainer(PersistenceController.preview.container)
            .environmentObject(TTSService.shared)
    }
}

@MainActor
private var previewCardSet: CardSet {
    let container = PersistenceController.preview.container
    let cardSet = CardSet(name: "Sample Deck")
    container.mainContext.insert(cardSet)

    let card = Card(id: 1, front: "I think...", back: "Example 1<br>Example 2<br>Example 3<br>Example 4<br>Example 5", cardName: "Pattern", groupId: 1, groupName: "Group 1")
    card.cardSet = cardSet
    cardSet.cards.append(card)
    container.mainContext.insert(card)
    
    return cardSet
}
