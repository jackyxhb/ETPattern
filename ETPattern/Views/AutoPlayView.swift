//
//  AutoPlayView.swift
//  ETPattern
//
//  Created by admin on 04/12/2025.
//

import SwiftUI
import CoreData

struct AutoPlayView: View {
    let cardSet: CardSet

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var ttsService: TTSService

    @State private var cards: [Card] = []
    @State private var currentIndex: Int = 0
    @State private var isFlipped = false
    @State private var isPlaying = true
    @State private var scheduledTask: DispatchWorkItem?
    @State private var resumePhase: AutoPlayPhase = .front
    @State private var speechToken = UUID()
    @State private var activePhase: AutoPlayPhase = .front

    private let fallbackFrontDelay: TimeInterval = 1.0
    private let fallbackBackDelay: TimeInterval = 1.5
    private var progressKey: String {
        let id = cardSet.objectID.uriRepresentation().absoluteString
        return "autoPlayProgress-\(id)"
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            DesignSystem.Gradients.background
                .ignoresSafeArea()

            VStack(spacing: 28) {
                header

                if cards.isEmpty {
                    emptyState
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    AutoCardDisplay(card: cards[currentIndex], index: currentIndex, total: cards.count, isFlipped: isFlipped)
                        .frame(maxHeight: .infinity)

                    playbackInfo

                    playbackControls
                }
            }
            .padding()
        }
        .onAppear {
            prepareCards()
            startPlaybackIfPossible()
        }
        .onDisappear {
            stopPlayback()
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(cardSet.name ?? "Auto Play")
                    .font(.title.bold())
                    .foregroundColor(.white)
                Text("Automatic playback")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            Spacer()
            Button(action: dismissAuto) {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.2), in: Circle())
            }
            .accessibilityLabel("Close")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform")
                .font(.largeTitle)
                .foregroundColor(.white.opacity(0.7))
            Text("This deck has no cards to play.")
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
        }
    }

    private var playbackInfo: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Card \(currentIndex + 1) of \(cards.count)")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text(isFlipped ? "Examples" : "Pattern")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            ProgressView(value: Double(currentIndex + 1), total: Double(cards.count))
                .tint(DesignSystem.Colors.highlight)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var playbackControls: some View {
        HStack(spacing: 16) {
            Button(action: togglePlayback) {
                Label(isPlaying ? "Pause" : "Play", systemImage: isPlaying ? "pause.fill" : "play.fill")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(DesignSystem.Gradients.accent)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

            Button(action: advanceToNextManually) {
                Label("Skip", systemImage: "forward.end.fill")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(DesignSystem.Gradients.success)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
        .buttonStyle(.plain)
    }

    private func prepareCards() {
        guard cards.isEmpty, let setCards = cardSet.cards as? Set<Card> else { return }
        let sorted = setCards.sorted { ($0.front ?? "") < ($1.front ?? "") }
        cards = sorted
        currentIndex = 0
        restoreProgressIfAvailable()
    }

    private func startPlaybackIfPossible() {
        guard !cards.isEmpty else { return }
        isPlaying = true
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
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            isFlipped = false
        }
        speakPhase(.front)
    }

    private func flipToBack() {
        guard isPlaying, !cards.isEmpty else { return }
        withAnimation(.easeInOut(duration: 0.6)) {
            isFlipped = true
        }
        speakPhase(.back)
    }

    private func moveToNextCard() {
        guard isPlaying, !cards.isEmpty else { return }
        currentIndex = (currentIndex + 1) % cards.count
        playFrontSide()
    }

    private func advanceToNextManually() {
        guard !cards.isEmpty else { return }
        resetSpeechFlow()
        currentIndex = (currentIndex + 1) % cards.count
        if isPlaying {
            playFrontSide()
        } else {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isFlipped = false
            }
        }
        saveProgress()
    }

    private func togglePlayback() {
        if isPlaying {
            pausePlayback()
        } else {
            isPlaying = true
            playFrontSide()
        }
    }

    private func pausePlayback() {
        isPlaying = false
        resetSpeechFlow()
        saveProgress()
    }

    private func stopPlayback() {
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
            guard isPlaying, speechToken == token, activePhase == phase else { return }
            advance(from: phase)
        }
    }

    private func advance(from phase: AutoPlayPhase) {
        switch phase {
        case .front:
            flipToBack()
        case .back:
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
        let progress = AutoPlayProgress(index: currentIndex, phase: isFlipped ? .back : .front)
        if let data = try? JSONEncoder().encode(progress) {
            UserDefaults.standard.set(data, forKey: progressKey)
        }
    }

    private func restoreProgressIfAvailable() {
        guard
            let data = UserDefaults.standard.data(forKey: progressKey),
            let progress = try? JSONDecoder().decode(AutoPlayProgress.self, from: data),
            !cards.isEmpty
        else { return }

        let safeIndex = min(max(progress.index, 0), cards.count - 1)
        currentIndex = safeIndex
        isFlipped = progress.phase == .back
        resumePhase = progress.phase
    }
}

private struct AutoCardDisplay: View {
    let card: Card
    let index: Int
    let total: Int
    let isFlipped: Bool

    var body: some View {
        ZStack {
            CardFace(
                text: card.front ?? "No front",
                pattern: "",
                isFront: true,
                currentIndex: index,
                totalCards: total
            )
            .opacity(isFlipped ? 0 : 1)
            .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))

            CardFace(
                text: formatBackText,
                pattern: card.front ?? "",
                isFront: false,
                currentIndex: index,
                totalCards: total
            )
            .opacity(isFlipped ? 1 : 0)
            .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
        }
        .frame(maxWidth: .infinity, maxHeight: 400)
        .padding(.vertical)
    }

    private var formatBackText: String {
        (card.back ?? "No back").replacingOccurrences(of: "<br>", with: "\n")
    }
}

private enum AutoPlayPhase: String, Codable {
    case front
    case back
}

private struct AutoPlayProgress: Codable {
    let index: Int
    let phase: AutoPlayPhase
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
