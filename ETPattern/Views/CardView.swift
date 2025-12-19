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

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let card = Card(context: context)
    card.front = "I think..."
    card.back = "I think it's going to rain.<br>I think you should study more.<br>I think this is a good idea.<br>I think she's coming tomorrow.<br>I think we need to talk."

    return CardView(card: card, currentIndex: 0, totalCards: 300)
        .environmentObject(TTSService())
}