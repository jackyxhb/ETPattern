import SwiftUI
import SwiftData
import UIKit

struct AutoPlayView: View {
    let cardSet: CardSet
    let modelContext: ModelContext // Passed in via init, or could use Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) var theme
    @EnvironmentObject private var ttsService: TTSService

    @State private var viewModel: AutoPlayViewModel?
    
    // Local state for animation/interaction, mirroring VM state where needed for transitions
    @State private var currentTask: Task<Void, Never>?
    @State private var resumePhase: AutoPlayPhase = .front
    @State private var speechToken = UUID()
    @State private var cardToken = UUID()
    @State private var activePhase: AutoPlayPhase = .front
    
    // Metrics
    private var fallbackFrontDelay: TimeInterval { theme.metrics.autoPlayFallbackFrontDelay }
    private var fallbackBackDelay: TimeInterval { theme.metrics.autoPlayFallbackBackDelay }
    private var interCardDelay: TimeInterval { theme.metrics.autoPlayInterCardDelay }

    init(cardSet: CardSet, modelContext: ModelContext) {
        self.cardSet = cardSet
        self.modelContext = modelContext
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            theme.gradients.background
                .ignoresSafeArea()

            if let viewModel = viewModel {
                content(with: viewModel)
            } else {
                ProgressView()
            }
        }
        .onAppear {
            if viewModel == nil {
                let service = SessionService(modelContext: modelContext)
                viewModel = AutoPlayViewModel(cardSet: cardSet, service: service, ttsService: ttsService)
            }
            Task {
                await viewModel?.startSession()
                startPlaybackIfPossible()
            }
        }
        .onDisappear {
            stopPlayback()
            viewModel?.stopSession()
        }
        .onChange(of: viewModel?.isPlaying) { _, playing in
            if playing == true {
                disableIdleTimer()
            } else {
                enableIdleTimer()
            }
        }
    }
    
    @ViewBuilder
    private func content(with vm: AutoPlayViewModel) -> some View {
        VStack(spacing: theme.metrics.autoPlayViewSpacing) {
            header
            
            if vm.cards.isEmpty {
                emptyState
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                SharedCardDisplayView(
                    frontText: vm.currentCard?.front ?? "No front",
                    backText: (vm.currentCard?.back ?? "No back").replacingOccurrences(of: "<br>", with: "\n"),
                    groupName: vm.currentCard?.groupName ?? "",
                    cardName: vm.currentCard?.cardName ?? "",
                    isFlipped: vm.isFlipped,
                    currentIndex: vm.currentIndex,
                    totalCards: vm.cards.count,
                    cardId: (vm.currentCard?.id).flatMap { Int($0) },
                    showSwipeFeedback: false,
                    swipeDirection: nil,
                    theme: theme
                )
            }
        }
        .padding(.horizontal, theme.metrics.autoPlayViewHorizontalPadding)
        .safeAreaInset(edge: .bottom) {
            bottomControlBar(vm: vm)
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

    private func bottomControlBar(vm: AutoPlayViewModel) -> some View {
        SharedBottomControlBarView(
            strategyToggleAction: {
                UIImpactFeedbackGenerator.lightImpact()
                vm.cycleStrategy()
                // Update is implicit via observation
            },
            previousAction: {
                UIImpactFeedbackGenerator.lightImpact()
                goToPreviousCard(vm: vm)
            },
            nextAction: {
                UIImpactFeedbackGenerator.lightImpact()
                advanceToNextManually(vm: vm)
            },
            closeAction: {
                UIImpactFeedbackGenerator.lightImpact()
                dismissAuto(vm: vm)
            },
            isPreviousDisabled: vm.currentIndex == 0,
            strategy: vm.currentStrategy,
            currentPosition: vm.cards.count > 0 ? vm.currentIndex + 1 : 0,
            totalCards: vm.cards.count,
            theme: theme,
            previousHint: vm.currentIndex == 0 ? "No previous card available" : "Go to previous card",
            nextHint: "Skip to next card"
        ) {
            playPauseButton(vm: vm)
        }
    }

    private func playPauseButton(vm: AutoPlayViewModel) -> some View {
        Button(action: {
            UIImpactFeedbackGenerator.mediumImpact()
            togglePlayback(vm: vm)
        }) {
            Image(systemName: vm.isPlaying ? "pause.fill" : "play.fill")
                .font(theme.metrics.title)
                .foregroundColor(theme.colors.textPrimary)
                .frame(width: theme.metrics.autoPlayButtonSize, height: theme.metrics.autoPlayButtonSize)
                .background(theme.gradients.accent)
                .clipShape(Circle())
                .shadow(color: theme.colors.highlight.opacity(0.3), radius: theme.metrics.autoPlayButtonShadowRadius, x: 0, y: theme.metrics.autoPlayButtonShadowY)
        }
        .accessibilityLabel(vm.isPlaying ? "Pause" : "Play")
    }

    // MARK: - Playback Logic
    // Note: Most state is now in VM, but animation sequencing remains in View
    // because it handles strictly visual transitions (flips, delays).
    
    private func startPlaybackIfPossible() {
        guard let vm = viewModel, !vm.cards.isEmpty else { return }
        // vm.togglePlayback() // Already defaulted to true in VM init?
        disableIdleTimer()
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
        guard let vm = viewModel, vm.isPlaying, !vm.cards.isEmpty else { return }
        _ = beginCard()
        withAnimation(.smooth) {
            vm.setFlipped(false)
        }
        speakPhase(.front)
    }

    private func flipToBack() {
        guard let vm = viewModel, vm.isPlaying, !vm.cards.isEmpty else { return }
        withAnimation(.smooth) {
            vm.setFlipped(true)
        }
        speakPhase(.back)
    }

    private func moveToNextCard() {
        guard let vm = viewModel, vm.isPlaying, !vm.cards.isEmpty else { return }
        vm.next()
        playFrontSide()
    }

    private func advanceToNextManually(vm: AutoPlayViewModel) {
        guard !vm.cards.isEmpty else { return }

        // Completely stop current speech and reset all state
        ttsService.stop()
        currentTask?.cancel()

        // Generate new token to invalidate any pending operations
        let newToken = UUID()
        speechToken = newToken
        cardToken = newToken
        activePhase = .front

        // Move to next card
        vm.next()

        // Reset card state
        withAnimation(.smooth) {
            vm.setFlipped(false)
        }

        // If playing, start fresh auto-play sequence for the new card
        if vm.isPlaying {
            currentTask = Task {
                try? await Task.sleep(for: .milliseconds(100))
                guard !Task.isCancelled, vm.isPlaying, speechToken == newToken else { return }
                await MainActor.run {
                    playFrontSide()
                }
            }
        }
    }

    private func goToPreviousCard(vm: AutoPlayViewModel) {
        guard !vm.cards.isEmpty else { return }

        // Completely stop current speech and reset all state
        ttsService.stop()
        currentTask?.cancel()

        // Generate new token to invalidate any pending operations
        let newToken = UUID()
        speechToken = newToken
        cardToken = newToken
        activePhase = .front

        // Move to previous card
        vm.previous()

        // Reset card state
        withAnimation(.smooth) {
            vm.setFlipped(false)
        }

        // If playing, start fresh auto-play sequence for the new card
        if vm.isPlaying {
            currentTask = Task {
                try? await Task.sleep(for: .milliseconds(100))
                guard !Task.isCancelled, vm.isPlaying, speechToken == newToken else { return }
                await MainActor.run {
                    playFrontSide()
                }
            }
        }
    }

    private func togglePlayback(vm: AutoPlayViewModel) {
        vm.togglePlayback()
        if vm.isPlaying {
            disableIdleTimer()
            continueFromResumePhase()
        } else {
            pausePlayback()
        }
    }

    private func pausePlayback() {
        guard let vm = viewModel else { return }
        // vm.isPlaying is already false
        resumePhase = vm.isFlipped ? .back : .front
        enableIdleTimer()
        resetSpeechFlow()
    }

    private func stopPlayback() {
        viewModel?.stopSession()
        enableIdleTimer()
        resetSpeechFlow()
    }

    private func dismissAuto(vm: AutoPlayViewModel) {
        stopPlayback()
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
        // ttsService.stop() // handled in VM toggle
    }

    private func beginCard() -> UUID {
        currentTask?.cancel()
        activePhase = .front
        let token = UUID()
        cardToken = token
        speechToken = token
        return token
    }

    private func speakPhase(_ phase: AutoPlayPhase) {
        activePhase = phase
        guard let vm = viewModel, let currentCard = vm.currentCard else { return }
        let text = text(for: phase, at: currentCard).trimmingCharacters(in: .whitespacesAndNewlines)
        let currentCardToken = cardToken

        guard !text.isEmpty else {
            schedule(after: fallbackDelay(for: phase), token: currentCardToken) {
                guard let vm = self.viewModel, vm.isPlaying, self.cardToken == currentCardToken, self.activePhase == phase else { return }
                self.advance(from: phase)
            }
            return
        }

        ttsService.speak(text) {
            Task { @MainActor in
                guard let vm = self.viewModel, vm.isPlaying, self.cardToken == currentCardToken, self.activePhase == phase else { return }
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
                guard let vm = self.viewModel, !Task.isCancelled, vm.isPlaying else { return }
                await MainActor.run {
                    moveToNextCard()
                }
            } catch {
                // Task was cancelled
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
        AutoPlayView(cardSet: previewCardSet, modelContext: PersistenceController.preview.container.mainContext)
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
