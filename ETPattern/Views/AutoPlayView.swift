import SwiftUI
import SwiftData
import UIKit
import ETPatternModels
import ETPatternServices

struct AutoPlayView: View {
    let cardSet: CardSet

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.theme) var theme
    @EnvironmentObject private var ttsService: TTSService

    @StateObject private var sessionManager: SessionManager
    @State private var currentCard: Card?
    @State private var isFlipped = false
    @State private var isPlaying = true
    @State private var currentTask: Task<Void, Never>?
    @State private var resumePhase: AutoPlayPhase = .front
    @State private var speechToken = UUID()
    @State private var cardToken = UUID()
    @State private var activePhase: AutoPlayPhase = .front

    private var fallbackFrontDelay: TimeInterval { theme.metrics.autoPlayFallbackFrontDelay }
    private var fallbackBackDelay: TimeInterval { theme.metrics.autoPlayFallbackBackDelay }
    private var interCardDelay: TimeInterval { theme.metrics.autoPlayInterCardDelay }

    init(cardSet: CardSet) {
        self.cardSet = cardSet
        _sessionManager = StateObject(wrappedValue: SessionManager(cardSet: cardSet))
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            theme.gradients.background
                .ignoresSafeArea()

            VStack(spacing: theme.metrics.autoPlayViewSpacing) {
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
                        showSwipeFeedback: false,
                        swipeDirection: nil,
                        theme: theme
                    )
                }
            }
            .padding(.horizontal, theme.metrics.autoPlayViewHorizontalPadding)
            .safeAreaInset(edge: .bottom) {
                bottomControlBar
            }
        }
        .onAppear {
            sessionManager.prepareSession()
            updateCurrentCard()
            startPlaybackIfPossible()
        }
        .onDisappear {
            stopPlayback()
            sessionManager.saveProgress()
        }
        .onChange(of: isPlaying) { playing in
            if playing {
                disableIdleTimer()
            } else {
                enableIdleTimer()
            }
        }
    }

    private var header: some View {
        SharedHeaderView(
            title: cardSet.name,
            subtitle: "Automatic playback",
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
            orderToggleAction: {
                UIImpactFeedbackGenerator.lightImpact()
                sessionManager.toggleOrderMode()
            },
            previousAction: {
                UIImpactFeedbackGenerator.lightImpact()
                goToPreviousCard()
            },
            nextAction: {
                UIImpactFeedbackGenerator.lightImpact()
                advanceToNextManually()
            },
            closeAction: {
                UIImpactFeedbackGenerator.lightImpact()
                dismissAuto()
            },
            isPreviousDisabled: sessionManager.currentIndex == 0,
            isRandomOrder: sessionManager.isRandomOrder,
            currentPosition: sessionManager.getCards().count > 0 ? sessionManager.currentIndex + 1 : 0,
            totalCards: sessionManager.getCards().count,
            theme: theme,
            previousHint: sessionManager.currentIndex == 0 ? "No previous card available" : "Go to previous card",
            nextHint: "Skip to next card"
        ) {
            playPauseButton
        }
    }

    private var playPauseButton: some View {
        Button(action: {
            UIImpactFeedbackGenerator.mediumImpact()
            togglePlayback()
        }) {
            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                .font(theme.metrics.title)
                .foregroundColor(theme.colors.textPrimary)
                .frame(width: theme.metrics.autoPlayButtonSize, height: theme.metrics.autoPlayButtonSize)
                .background(theme.gradients.accent)
                .clipShape(Circle())
                .shadow(color: theme.colors.highlight.opacity(0.3), radius: theme.metrics.autoPlayButtonShadowRadius, x: 0, y: theme.metrics.autoPlayButtonShadowY)
        }
        .accessibilityLabel(isPlaying ? "Pause" : "Play")
    }



    private func startPlaybackIfPossible() {
        guard !sessionManager.getCards().isEmpty else { return }
        isPlaying = true
        disableIdleTimer() // Prevent device sleep during auto-play

        // If this is the start of a fresh session (not resuming), count the first card
        if sessionManager.cardsPlayedInSession == 0 {
            sessionManager.cardsPlayedInSession = 1
        }

        continueFromResumePhase()
    }

    private func continueFromResumePhase() {
        switch resumePhase {
        case .front:
            playFrontSide()
        case .back:
            flipToBack()
        }
        resumePhase = .front
    }

    private func playFrontSide() {
        guard isPlaying, !sessionManager.getCards().isEmpty else { return }
        _ = beginCard()
        withAnimation(.smooth) {
            isFlipped = false
        }
        speakPhase(.front)
    }

    private func flipToBack() {
        guard isPlaying, !sessionManager.getCards().isEmpty else { return }
        withAnimation(.smooth) {
            isFlipped = true
        }
        speakPhase(.back)
    }

    private func moveToNextCard() {
        guard isPlaying, !sessionManager.getCards().isEmpty else { return }
        sessionManager.moveToNext()
        updateCurrentCard()
        sessionManager.saveProgress()
        playFrontSide()
    }

    private func advanceToNextManually() {
        guard !sessionManager.getCards().isEmpty else { return }

        // Completely stop current speech and reset all state
        ttsService.stop()
        currentTask?.cancel()

        // Generate new token to invalidate any pending operations
        let newToken = UUID()
        speechToken = newToken
        cardToken = newToken
        activePhase = .front

        // Move to next card
        sessionManager.moveToNext()
        updateCurrentCard()
        sessionManager.saveProgress()

        // Reset card state
        withAnimation(.smooth) {
            isFlipped = false
        }

        // If playing, start fresh auto-play sequence for the new card
        // Use a small delay to ensure TTS state is fully reset
        if isPlaying {
            currentTask = Task {
                do {
                    try await Task.sleep(for: .milliseconds(100))
                    // Double-check we're still in the same state
                    guard !Task.isCancelled, isPlaying, speechToken == newToken else { return }
                    await MainActor.run {
                        playFrontSide()
                    }
                } catch {
                    // Task was cancelled, ignore
                }
            }
        }
    }

    private func goToPreviousCard() {
        guard !sessionManager.getCards().isEmpty else { return }

        // Completely stop current speech and reset all state
        ttsService.stop()
        currentTask?.cancel()

        // Generate new token to invalidate any pending operations
        let newToken = UUID()
        speechToken = newToken
        cardToken = newToken
        activePhase = .front

        // Move to previous card
        sessionManager.moveToPrevious()
        updateCurrentCard()
        sessionManager.saveProgress()

        // Reset card state
        withAnimation(.smooth) {
            isFlipped = false
        }

        // If playing, start fresh auto-play sequence for the new card
        // Use a small delay to ensure TTS state is fully reset
        if isPlaying {
            currentTask = Task {
                do {
                    try await Task.sleep(for: .milliseconds(100))
                    // Double-check we're still in the same state
                    guard !Task.isCancelled, isPlaying, speechToken == newToken else { return }
                    await MainActor.run {
                        playFrontSide()
                    }
                } catch {
                    // Task was cancelled, ignore
                }
            }
        }

        sessionManager.saveProgress()
    }

    private func togglePlayback() {
        if isPlaying {
            pausePlayback()
        } else {
            isPlaying = true
            disableIdleTimer()
            continueFromResumePhase()
        }
    }

    private func pausePlayback() {
        isPlaying = false
        resumePhase = isFlipped ? .back : .front
        enableIdleTimer() // Allow device sleep when paused
        resetSpeechFlow()
        sessionManager.saveProgress()
    }

    private func stopPlayback() {
        isPlaying = false
        enableIdleTimer() // Allow device sleep when stopped
        resetSpeechFlow()

    }

    private func dismissAuto() {
        stopPlayback()
        sessionManager.saveProgress()
        dismiss()
    }

    private func schedule(after interval: TimeInterval, token: UUID, action: @escaping () -> Void) {
        currentTask?.cancel()
        currentTask = Task {
            do {
                try await Task.sleep(for: .seconds(interval))
                guard !Task.isCancelled, speechToken == token else { return }
                await MainActor.run {
                    action()
                }
            } catch {
                // Task was cancelled, ignore
            }
        }
    }

    private func resetSpeechFlow() {
        currentTask?.cancel()
        speechToken = UUID()
        cardToken = UUID()
        activePhase = .front
        ttsService.stop()
    }

    private func beginCard() -> UUID {
        currentTask?.cancel()
        activePhase = .front
        let token = UUID()
        cardToken = token
        speechToken = token
        return token
    }

    private func updateCurrentCard() {
        currentCard = sessionManager.currentCard
    }

    private func speakPhase(_ phase: AutoPlayPhase) {
        activePhase = phase
        guard let currentCard = currentCard else { return }
        let text = text(for: phase, at: currentCard).trimmingCharacters(in: .whitespacesAndNewlines)
        let currentCardToken = cardToken

        guard !text.isEmpty else {
            schedule(after: fallbackDelay(for: phase), token: currentCardToken) {
                guard isPlaying, cardToken == currentCardToken, activePhase == phase else { return }
                advance(from: phase)
            }
            return
        }

        ttsService.speak(text) {
            // Triple-check token and state are still valid before advancing
            Task { @MainActor in
                guard self.isPlaying, self.cardToken == currentCardToken, self.activePhase == phase else { return }
                self.advance(from: phase)
            }
        }
    }

    private func advance(from phase: AutoPlayPhase) {
        switch phase {
        case .front:
            flipToBack()
        case .back:
            enqueueNextCard()
        }
    }

    private func enqueueNextCard() {
        currentTask?.cancel()
        currentTask = Task {
            do {
                try await Task.sleep(for: .seconds(interCardDelay))
                guard !Task.isCancelled, isPlaying else { return }
                await MainActor.run {
                    moveToNextCard()
                }
            } catch {
                // Task was cancelled, ignore
            }
        }
    }

    private func fallbackDelay(for phase: AutoPlayPhase) -> TimeInterval {
        switch phase {
        case .front: return fallbackFrontDelay
        case .back: return fallbackBackDelay
        }
    }

    private func text(for phase: AutoPlayPhase, at card: Card) -> String {
        switch phase {
        case .front:
            return card.front
        case .back:
            return card.back.replacingOccurrences(of: "<br>", with: "\n")
        }
    }

    private func disableIdleTimer() {
        UIApplication.shared.isIdleTimerDisabled = true
    }

    private func enableIdleTimer() {
        UIApplication.shared.isIdleTimerDisabled = false
    }
}

private enum AutoPlayPhase: String, Codable {
    case front
    case back
}

#Preview {
    NavigationView {
        AutoPlayView(cardSet: previewCardSet)
            .modelContainer(PersistenceController.preview.container)
            .environmentObject(TTSService.shared)
    }
}

@MainActor
private var previewCardSet: CardSet {
    let container = PersistenceController.preview.container
    let cardSet = CardSet(name: "Sample Deck")
    container.mainContext.insert(cardSet)
    return cardSet
}
