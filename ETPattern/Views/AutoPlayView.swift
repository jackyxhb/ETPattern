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

    private let frontDuration: TimeInterval = 3.0
    private let backDuration: TimeInterval = 4.0
    private var progressKey: String {
        let id = cardSet.objectID.uriRepresentation().absoluteString
        return "autoPlayProgress-\(id)"
    }

    var body: some View {
        VStack(spacing: 24) {
            header

            if cards.isEmpty {
                emptyState
            } else {
                AutoCardDisplay(card: cards[currentIndex], index: currentIndex, total: cards.count, isFlipped: isFlipped)
                    .frame(maxHeight: .infinity)

                playbackInfo

                playbackControls
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
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
            VStack(alignment: .leading, spacing: 4) {
                Text(cardSet.name ?? "Auto Play")
                    .font(.title2.bold())
                Text("Automatic playback")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button(action: dismissAuto) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel("Close")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            Text("This deck has no cards to play.")
                .font(.headline)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var playbackInfo: some View {
        VStack(spacing: 6) {
            Text("Card \(currentIndex + 1) of \(cards.count)")
                .font(.headline)
            ProgressView(value: Double(currentIndex + 1), total: Double(cards.count))
                .tint(.accentColor)
        }
        .padding(.horizontal)
    }

    private var playbackControls: some View {
        HStack(spacing: 16) {
            Button(action: togglePlayback) {
                Label(isPlaying ? "Pause" : "Play", systemImage: isPlaying ? "pause.fill" : "play.fill")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentColor.opacity(0.15))
                    .foregroundColor(.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            Button(action: advanceToNextManually) {
                Label("Skip", systemImage: "forward.end.fill")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue.opacity(0.15))
                    .foregroundColor(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
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
        speak(text: cards[currentIndex].front ?? "")
        schedule(after: frontDuration) {
            flipToBack()
        }
    }

    private func flipToBack() {
        guard isPlaying, !cards.isEmpty else { return }
        withAnimation(.easeInOut(duration: 0.6)) {
            isFlipped = true
        }
        speak(text: formatBackText(for: cards[currentIndex]))
        schedule(after: backDuration) {
            moveToNextCard()
        }
    }

    private func moveToNextCard() {
        guard isPlaying, !cards.isEmpty else { return }
        currentIndex = (currentIndex + 1) % cards.count
        playFrontSide()
    }

    private func advanceToNextManually() {
        guard !cards.isEmpty else { return }
        scheduledTask?.cancel()
        currentIndex = (currentIndex + 1) % cards.count
        if isPlaying {
            playFrontSide()
        } else {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isFlipped = false
            }
            ttsService.stop()
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
        scheduledTask?.cancel()
        ttsService.stop()
        saveProgress()
    }

    private func stopPlayback() {
        scheduledTask?.cancel()
        ttsService.stop()
        saveProgress()
    }

    private func dismissAuto() {
        stopPlayback()
        dismiss()
    }

    private func schedule(after interval: TimeInterval, action: @escaping () -> Void) {
        scheduledTask?.cancel()
        let workItem = DispatchWorkItem(block: action)
        scheduledTask = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + interval, execute: workItem)
    }

    private func speak(text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        ttsService.speak(text)
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
