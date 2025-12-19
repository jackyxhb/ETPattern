//
//  CardView.swift
//  ETPattern
//
//  Created by admin on 25/11/2025.
//

import SwiftUI
import AVFoundation
import CoreData

struct CardView: View {
    let card: Card
    let currentIndex: Int
    let totalCards: Int
    @State private var isFlipped = false
    @Environment(\.theme) var theme
    @EnvironmentObject private var ttsService: TTSService

    var body: some View {
        ZStack {
            CardFace(text: card.front ?? "No front", pattern: "", isFront: true, currentIndex: currentIndex, totalCards: totalCards)
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))

            CardFace(text: formatBackText(), pattern: card.front ?? "", isFront: false, currentIndex: currentIndex, totalCards: totalCards)
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onTapGesture {
            UIImpactFeedbackGenerator.lightImpact()
            withAnimation(.bouncy) {
                isFlipped.toggle()
                speakCurrentText()
            }
        }
        .onAppear {
            speakCurrentText()
        }
        .onChange(of: currentIndex) { _ in
            // Reset to front side when card changes
            isFlipped = false
            // Stop any ongoing speech from previous card
            ttsService.stop()
            speakCurrentText()
        }
    }

    private func formatBackText() -> String {
        guard let backText = card.back else { return "No back" }
        // Replace <br> with newlines for proper display
        return backText.replacingOccurrences(of: "<br>", with: "\n")
    }

    private func speakCurrentText() {
        let textToSpeak = isFlipped ? formatBackText() : (card.front ?? "")
        ttsService.speak(textToSpeak)
    }
}

struct CardFace: View {
    let text: String
    let pattern: String
    let isFront: Bool
    let currentIndex: Int
    let totalCards: Int

    @Environment(\.theme) var theme

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: theme.metrics.cornerRadius)
                .fill(theme.gradients.card)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.metrics.cornerRadius)
                        .stroke(theme.colors.surfaceLight, lineWidth: 1.5)
                )
                .shadow(color: theme.colors.shadow, radius: 30, x: 0, y: 30)

            VStack(alignment: .leading, spacing: 28) {
                header
                Spacer(minLength: 0)
                if isFront {
                    Text(text.isEmpty ? "No content" : text)
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundColor(theme.colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .minimumScaleFactor(0.5)
                        .lineLimit(3)
                } else {
                    backContent
                }
                Spacer(minLength: 0)
            }
            .padding(20)
        }
        .padding(8)
    }

    private var header: some View {
        HStack {
            Text("CARD \(currentIndex + 1)/\(max(totalCards, 1))")
                .font(.caption.monospacedDigit())
                .foregroundColor(theme.colors.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(theme.colors.surfaceLight)
                .clipShape(Capsule())

            Spacer()

            if !pattern.isEmpty, !isFront {
                Text(pattern)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(theme.colors.highlight)
                    .lineLimit(1)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(theme.colors.surfaceMedium)
                    .clipShape(Capsule())
            }
        }
    }

    @ViewBuilder
    private var backContent: some View {
        let examples = text.components(separatedBy: "\n").filter { !$0.isEmpty }

        VStack(alignment: .leading, spacing: 18) {
            ForEach(Array(examples.enumerated()), id: \.offset) { index, example in
                HStack(alignment: .top, spacing: 12) {
                    Text(String(format: "%02d", index + 1))
                        .font(.caption.bold())
                        .foregroundColor(theme.colors.textSecondary)
                        .padding(8)
                        .background(theme.colors.surfaceLight)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    Text(example)
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(theme.colors.textPrimary)
                        .lineSpacing(6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 6)
            }
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let card = Card(context: context)
    card.front = "I think..."
    card.back = "I think it's going to rain.<br>I think you should study more.<br>I think this is a good idea.<br>I think she's coming tomorrow.<br>I think we need to talk."

    return CardView(card: card, currentIndex: 0, totalCards: 300)
        .environmentObject(TTSService())
}