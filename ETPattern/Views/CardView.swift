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
    @EnvironmentObject private var ttsService: TTSService

    var body: some View {
        FlippableCardView(
            frontText: card.front ?? "No front",
            backText: formatBackText(),
            pattern: card.front ?? "",
            currentIndex: currentIndex,
            totalCards: totalCards,
            isFlipped: $isFlipped,
            onFlip: nil,
            onAppearAction: nil
        )
        .onChange(of: currentIndex) { _ in
            // Reset to front side when card changes
            isFlipped = false
            // Stop any ongoing speech from previous card
            ttsService.stop()
        }
    }

    private func formatBackText() -> String {
        guard let backText = card.back else { return "No back" }
        return backText.formatCardBackText()
    }
}

struct CardFace: View {
    let text: String
    let pattern: String
    let isFront: Bool
    let currentIndex: Int
    let totalCards: Int

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DesignSystem.Metrics.cornerRadius)
                .fill(DesignSystem.Gradients.card)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.Metrics.cornerRadius)
                        .stroke(DesignSystem.Colors.stroke, lineWidth: 1.5)
                )
                .shadow(color: DesignSystem.Metrics.shadow, radius: 30, x: 0, y: 30)

            VStack(alignment: .leading, spacing: 28) {
                header
                Spacer(minLength: 0)
                if isFront {
                    Text(text.isEmpty ? "No content" : text)
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
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
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())

            Spacer()

            if !pattern.isEmpty, !isFront {
                Text(pattern)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(DesignSystem.Colors.highlight)
                    .lineLimit(1)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.12))
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
                        .foregroundColor(.white.opacity(0.7))
                        .padding(8)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    Text(example)
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
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