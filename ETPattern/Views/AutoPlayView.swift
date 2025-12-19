//
//  AutoPlayView.swift
//  ETPattern
//
//  Created by admin on 04/12/2025.
//

import SwiftUI
import CoreData
import UIKit

struct AutoPlayView: View {
    let cardSet: CardSet

    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) var theme
    @EnvironmentObject private var ttsService: TTSService

    @State private var cards: [Card] = []
    @State private var originalCards: [Card] = [] // Keep original order for sequential mode
    @State private var currentIndex: Int = 0
    @State private var isFlipped = false
    @State private var isPlaying = true
    @State private var scheduledTask: DispatchWorkItem?
    @State private var resumePhase: AutoPlayPhase = .front
    @State private var speechToken = UUID()
    @State private var activePhase: AutoPlayPhase = .front
    @State private var isRandomOrder = false
    @State private var cardsPlayedInSession: Int = 0

    private let fallbackFrontDelay: TimeInterval = 1.0
    private let fallbackBackDelay: TimeInterval = 1.5
    private let interCardDelay: TimeInterval = 1.0
    private var progressKey: String {
        let id = cardSet.objectID.uriRepresentation().absoluteString
        return "autoPlayProgress-\(id)"
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            theme.gradients.background
                .ignoresSafeArea()

            VStack(spacing: 8) {
                header

                if cards.isEmpty {
                    emptyState
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    SharedCardDisplayView(
                        frontText: cards[currentIndex].front ?? "No front",
                        backText: formatBackText,
                        pattern: cards[currentIndex].front ?? "",
                        isFlipped: isFlipped,
                        currentIndex: currentIndex,
                        totalCards: cards.count,
                        showSwipeFeedback: false,
                        swipeDirection: nil,
                        theme: theme
                    )
                }
            }
            .padding(.horizontal, 4)
            .safeAreaInset(edge: .bottom) {
                bottomControlBar
            }
        }
        .onAppear {
            prepareCards()
            startPlaybackIfPossible()
        }
        .onDisappear {
            stopPlayback()
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
            title: cardSet.name ?? "Auto Play",
            subtitle: "Automatic playback",
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
                Text("No Cards to Play")
                    .font(theme.typography.title.weight(.bold))
                    .foregroundColor(theme.colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("This deck doesn't have any cards yet")
                    .font(theme.typography.title3)
                    .foregroundColor(theme.colors.highlight)
                    .multilineTextAlignment(.center)

                Text("Add some cards to this deck or import a CSV file to start auto-playing through your patterns.")
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
            currentPosition: cards.count > 0 ? ((cardsPlayedInSession - 1) % cards.count) + 1 : 0,
            totalCards: cards.count,
            theme: theme
        )
    }

    private var mainControlsView: some View {
        HStack(spacing: 16) {
            orderToggleButton
            Spacer()
            previousButton
            playPauseButton
            skipButton
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

    private var previousButton: some View {
        Button(action: {
            UIImpactFeedbackGenerator.lightImpact()
            goToPreviousCard()
        }) {
            Image(systemName: "backward.end.fill")
                .font(theme.typography.title3)
                .foregroundColor(theme.colors.textSecondary)
                .frame(width: 44, height: 44)
                .background(theme.colors.surfaceMedium)
                .clipShape(Circle())
        }
        .disabled(currentIndex == 0)
        .opacity(currentIndex == 0 ? 0.3 : 1)
        .accessibilityLabel("Previous Card")
    }

    private var playPauseButton: some View {
        Button(action: {
            UIImpactFeedbackGenerator.mediumImpact()
            togglePlayback()
        }) {
            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                .font(theme.typography.title)
                .foregroundColor(theme.colors.textPrimary)
                .frame(width: 60, height: 60)
                .background(theme.gradients.accent)
                .clipShape(Circle())
                .shadow(color: theme.colors.highlight.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .accessibilityLabel(isPlaying ? "Pause" : "Play")
    }

    private var skipButton: some View {
        Button(action: {
            UIImpactFeedbackGenerator.lightImpact()
            advanceToNextManually()
        }) {
            Image(systemName: "forward.end.fill")
                .font(theme.typography.title3)
                .foregroundColor(theme.colors.textPrimary)
                .frame(width: 44, height: 44)
                .background(theme.gradients.success)
                .clipShape(Circle())
        }
        .accessibilityLabel("Skip")
    }

    private var closeButton: some View {
        SharedCloseButton(
            theme: theme,
            action: {
                UIImpactFeedbackGenerator.lightImpact()
                dismissAuto()
            }
        )
    }

    private func prepareCards() {
        guard cards.isEmpty, let setCards = cardSet.cards as? Set<Card> else { return }
        let sorted = setCards.sorted { ($0.front ?? "") < ($1.front ?? "") }
        originalCards = sorted
        isRandomOrder = UserDefaults.standard.string(forKey: "autoPlayOrderMode") == "random"
        cardsPlayedInSession = 0 // Reset for fresh session
        applyOrderMode()
        restoreProgressIfAvailable()
    }

    private func applyOrderMode() {
        if isRandomOrder {
            cards = originalCards.shuffled()
        } else {
            cards = originalCards
        }
        // Reset to first card when changing order
        currentIndex = 0
        isFlipped = false
        resumePhase = .front
    }

    private func applyOrderModePreservingCurrentCard() {
        let currentCard = cards.isEmpty ? nil : cards[currentIndex]

        if isRandomOrder {
            cards = originalCards.shuffled()
        } else {
            cards = originalCards
        }

        // Try to find the same card in the new order
        if let currentCard = currentCard,
           let newIndex = cards.firstIndex(where: { $0.objectID == currentCard.objectID }) {
            currentIndex = newIndex
        } else {
            // If we can't find the card, reset to beginning
            currentIndex = 0
            isFlipped = false
            resumePhase = .front
        }
    }

    private func toggleOrderMode() {
        isRandomOrder.toggle()
        applyOrderModePreservingCurrentCard()
        // Continue playing without interruption
        // No need to stop and restart - just update the order
    }

    private func startPlaybackIfPossible() {
        guard !cards.isEmpty else { return }
        isPlaying = true
        disableIdleTimer() // Prevent device sleep during auto-play
        
        // If this is the start of a fresh session (not resuming), count the first card
        if cardsPlayedInSession == 0 {
            cardsPlayedInSession = 1
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
        guard isPlaying, !cards.isEmpty else { return }
        withAnimation(.smooth) {
            isFlipped = false
        }
        speakPhase(.front)
    }

    private func flipToBack() {
        guard isPlaying, !cards.isEmpty else { return }
        withAnimation(.smooth) {
            isFlipped = true
        }
        speakPhase(.back)
    }

    private func moveToNextCard() {
        guard isPlaying, !cards.isEmpty else { return }
        currentIndex = (currentIndex + 1) % cards.count
        cardsPlayedInSession += 1
        playFrontSide()
    }

    private func advanceToNextManually() {
        guard !cards.isEmpty else { return }

        // Completely stop current speech and reset all state
        ttsService.stop()
        scheduledTask?.cancel()

        // Generate new token to invalidate any pending operations
        let newToken = UUID()
        speechToken = newToken
        activePhase = .front

        // Move to next card
        currentIndex = (currentIndex + 1) % cards.count
        cardsPlayedInSession += 1

        // Reset card state
        withAnimation(.smooth) {
            isFlipped = false
        }

        // If playing, start fresh auto-play sequence for the new card
        // Use a small delay to ensure TTS state is fully reset
        if isPlaying {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // Double-check we're still in the same state
                guard self.isPlaying, self.speechToken == newToken else { return }
                self.playFrontSide()
            }
        }

        saveProgress()
    }

    private func goToPreviousCard() {
        guard !cards.isEmpty, currentIndex > 0 else { return }

        // Completely stop current speech and reset all state
        ttsService.stop()
        scheduledTask?.cancel()

        // Generate new token to invalidate any pending operations
        let newToken = UUID()
        speechToken = newToken
        activePhase = .front

        // Move to previous card
        currentIndex -= 1

        // Reset card state
        withAnimation(.smooth) {
            isFlipped = false
        }

        // If playing, start fresh auto-play sequence for the new card
        // Use a small delay to ensure TTS state is fully reset
        if isPlaying {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // Double-check we're still in the same state
                guard self.isPlaying, self.speechToken == newToken else { return }
                self.playFrontSide()
            }
        }

        saveProgress()
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
        saveProgress()
    }

    private func stopPlayback() {
        isPlaying = false
        enableIdleTimer() // Allow device sleep when stopped
        resetSpeechFlow()
        saveProgress()
    }

    private func dismissAuto() {
        stopPlayback()
        dismiss()
    }

    private func schedule(after interval: TimeInterval, token: UUID, action: @escaping () -> Void) {
        scheduledTask?.cancel()
        let workItem = DispatchWorkItem {
            guard speechToken == token else { return }
            action()
        }
        scheduledTask = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + interval, execute: workItem)
    }

    private func resetSpeechFlow() {
        scheduledTask?.cancel()
        speechToken = UUID()
        activePhase = .front
        ttsService.stop()
    }

    private func beginPhase(_ phase: AutoPlayPhase) -> UUID {
        scheduledTask?.cancel()
        activePhase = phase
        let token = UUID()
        speechToken = token
        return token
    }

    private func speakPhase(_ phase: AutoPlayPhase) {
        let token = beginPhase(phase)
        let text = text(for: phase, at: cards[currentIndex]).trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty else {
            schedule(after: fallbackDelay(for: phase), token: token) {
                guard isPlaying, speechToken == token, activePhase == phase else { return }
                advance(from: phase)
            }
            return
        }

        ttsService.speak(text) {
            // Triple-check token and state are still valid before advancing
            DispatchQueue.main.async {
                guard self.isPlaying, self.speechToken == token, self.activePhase == phase else { return }
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
        let token = speechToken
        schedule(after: interCardDelay, token: token) {
            guard isPlaying, speechToken == token else { return }
            moveToNextCard()
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
            return card.front ?? ""
        case .back:
            return formatBackText(for: card)
        }
    }

    private func formatBackText(for card: Card) -> String {
        (card.back ?? "").replacingOccurrences(of: "<br>", with: "\n")
    }

    private func saveProgress() {
        guard !cards.isEmpty else { return }
        let progress = AutoPlayProgress(index: currentIndex, phase: isFlipped ? .back : .front, isRandomOrder: isRandomOrder)
        if let data = try? JSONEncoder().encode(progress) {
            UserDefaults.standard.set(data, forKey: progressKey)
        }
    }

    private func restoreProgressIfAvailable() {
        guard
            let data = UserDefaults.standard.data(forKey: progressKey),
            let progress = try? JSONDecoder().decode(AutoPlayProgress.self, from: data),
            !originalCards.isEmpty
        else { return }

        // Apply the saved order mode
        isRandomOrder = progress.isRandomOrder
        applyOrderMode()

        // Restore position
        let safeIndex = min(max(progress.index, 0), cards.count - 1)
        currentIndex = safeIndex
        isFlipped = progress.phase == .back
        resumePhase = progress.phase
        
        // Set played count to current position (resumed session)
        cardsPlayedInSession = currentIndex + 1
    }

    private func disableIdleTimer() {
        UIApplication.shared.isIdleTimerDisabled = true
    }

    private func enableIdleTimer() {
        UIApplication.shared.isIdleTimerDisabled = false
    }

    private var formatBackText: String {
        (cards[currentIndex].back ?? "No back").replacingOccurrences(of: "<br>", with: "\n")
    }
}
//     let card: Card
//     let index: Int
//     let total: Int
//     let isFlipped: Bool
//
//     var body: some View {
//         ZStack {
//             CardFace(
//                 text: card.front ?? "No front",
//                 pattern: "",
//                 isFront: true,
//                 currentIndex: index,
//                 totalCards: total
//             )
//             .opacity(isFlipped ? 0 : 1)
//             .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
//
//             CardFace(
//                 text: formatBackText,
//                 pattern: card.front ?? "",
//                 isFront: false,
//                 currentIndex: index,
//                 totalCards: total
//             )
//             .opacity(isFlipped ? 1 : 0)
//             .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
//         }
//         .frame(maxWidth: .infinity, maxHeight: 400)
//         .padding(.vertical)
//     }
//
//     private var formatBackText: String {
//         (card.back ?? "No back").replacingOccurrences(of: "<br>", with: "\n")
//     }
// }

private enum AutoPlayPhase: String, Codable {
    case front
    case back
}

private struct AutoPlayProgress: Codable {
    let index: Int
    let phase: AutoPlayPhase
    let isRandomOrder: Bool
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let cardSet = CardSet(context: context)
    cardSet.name = "Preview Deck"

    let sampleCard = Card(context: context)
    sampleCard.front = "I think"
    sampleCard.back = "I think it's okay.<br>I think it's great.<br>I think we should go."
    cardSet.addToCards(sampleCard)

    return AutoPlayView(cardSet: cardSet)
        .environmentObject(TTSService())
}
