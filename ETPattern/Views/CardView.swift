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
    @State private var isFlipped = false
    @State private var ttsService = TTSService()

    var body: some View {
        ZStack {
            // Front of card
            CardFace(text: card.front ?? "No front", pattern: "", isFront: true)
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))

            // Back of card
            CardFace(text: formatBackText(), pattern: card.front ?? "", isFront: false)
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.6)) {
                isFlipped.toggle()
                speakCurrentText()
            }
        }
        .onAppear {
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

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(radius: 10)

            if isFront {
                // Front: Just the pattern, bold and centered
                Text(text)
                    .font(.system(size: 48, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                    .padding(40)
            } else {
                // Back: Pattern at top (smaller) + examples below
                VStack(spacing: 24) {
                    // Pattern at top
                    Text(pattern)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    // Examples below
                    let examples = text.components(separatedBy: "\n")
                    VStack(spacing: 12) {
                        ForEach(examples, id: \.self) { example in
                            if !example.isEmpty {
                                Text(example)
                                    .font(.system(size: 18))
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.primary)
                                    .lineSpacing(4)
                            }
                        }
                    }
                }
                .padding(40)
            }
        }
        .padding(20)
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let card = Card(context: context)
    card.front = "I think..."
    card.back = "I think it's going to rain.<br>I think you should study more.<br>I think this is a good idea.<br>I think she's coming tomorrow.<br>I think we need to talk."

    return CardView(card: card)
}