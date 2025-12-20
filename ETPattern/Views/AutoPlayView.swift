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

    @StateObject private var sessionManager: SessionManager
    @State private var currentCard: Card?
    @State private var isFlipped = false
    @State private var isPlaying = true
    @State private var scheduledTask: DispatchWorkItem?
    @State private var resumePhase: AutoPlayPhase = .front
    @State private var speechToken = UUID()
    @State private var cardToken = UUID()
    @State private var activePhase: AutoPlayPhase = .front

    private let fallbackFrontDelay: TimeInterval = 1.0
    private let fallbackBackDelay: TimeInterval = 1.5
    private let interCardDelay: TimeInterval = 1.0

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
                        pattern: currentCard?.groupName ?? "",
                        isFlipped: isFlipped,
                        currentIndex: sessionManager.currentIndex,
                        totalCards: sessionManager.getCards().count,
                        cardId: currentCard?.id != nil ? Int(currentCard!.id) : nil,
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
            sessionManager.prepareSession()
            updateCurrentCard()
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
            currentPosition: sessionManager.getCards().count > 0 ? ((sessionManager.cardsPlayedInSession - 1) % sessionManager.getCards().count) + 1 : 0,
            totalCards: sessionManager.getCards().count,
            theme: theme
        )
    }

    private var mainControlsView: some View {
        HStack(spacing: 16) {
            orderToggleButton
            Spacer()
            previousButton
            playPauseButton
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
            goToPreviousCard()
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

    private var nextButton: some View {
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
        playFrontSide()
    }

    private func advanceToNextManually() {
        guard !sessionManager.getCards().isEmpty else { return }

        // Completely stop current speech and reset all state
        ttsService.stop()
        scheduledTask?.cancel()

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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // Double-check we're still in the same state
                guard self.isPlaying, self.speechToken == newToken else { return }
                self.playFrontSide()
            }
        }
    }

    private func goToPreviousCard() {
        guard !sessionManager.getCards().isEmpty else { return }

        // Completely stop current speech and reset all state
        ttsService.stop()
        scheduledTask?.cancel()

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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // Double-check we're still in the same state
                guard self.isPlaying, self.speechToken == newToken else { return }
                self.playFrontSide()
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
        cardToken = UUID()
        activePhase = .front
        ttsService.stop()
    }

    private func beginCard() -> UUID {
        scheduledTask?.cancel()
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
            DispatchQueue.main.async {
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
        scheduledTask?.cancel()
        let workItem = DispatchWorkItem {
            guard self.isPlaying else { return }
            self.moveToNextCard()
        }
        scheduledTask = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + interCardDelay, execute: workItem)
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
            return card.front ?? "No front"
        case .back:
            return (card.back ?? "No back").replacingOccurrences(of: "<br>", with: "\n")
        }
    }

    private func disableIdleTimer() {
        UIApplication.shared.isIdleTimerDisabled = true
    }

    private func enableIdleTimer() {
        UIApplication.shared.isIdleTimerDisabled = false
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
