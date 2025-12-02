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
        ZStack {
            // Front of card
            CardFace(text: card.front ?? "No front", pattern: "", isFront: true, currentIndex: currentIndex, totalCards: totalCards)
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))

            // Back of card
            CardFace(text: formatBackText(), pattern: card.front ?? "", isFront: false, currentIndex: currentIndex, totalCards: totalCards)
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
        .onChange(of: card) { oldValue, newValue in
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

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )

            if isFront {
                // Front: Header with card number + pattern below
                VStack {
                    // Header with card number
                    Text("\(currentIndex + 1)/\(totalCards)")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    
                    Spacer()
                    
                    // Pattern text
                    Text(text)
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                        .minimumScaleFactor(0.5)
                        .lineLimit(3)
                    
                    Spacer()
                }
                .padding(32)
            } else {
                // Back: Pattern at top (smaller) + examples below
                VStack(spacing: 32) {
                    // Pattern at top
                    Text(pattern)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)

                    // Examples below
                    let examples = text.components(separatedBy: "\n")
                    VStack(spacing: 16) {
                        ForEach(examples.indices, id: \.self) { index in
                            let example = examples[index]
                            if !example.isEmpty {
                                HStack(alignment: .top, spacing: 12) {
                                    Text("\(index + 1).")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.secondary)
                                    Text(example)
                                        .font(.system(size: 18, weight: .regular, design: .rounded))
                                        .multilineTextAlignment(.leading)
                                        .foregroundColor(.primary)
                                        .lineSpacing(6)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }
                .padding(32)
            }
        }
        .padding(24)
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