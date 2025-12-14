//
//  FlippableCardView.swift
//  ETPattern
//
//  Created by GitHub Copilot on 15/12/2025.
//

import SwiftUI
import AVFoundation

struct FlippableCardView: View {
    let frontText: String
    let backText: String
    let pattern: String
    let currentIndex: Int
    let totalCards: Int
    @Binding var isFlipped: Bool
    @EnvironmentObject private var ttsService: TTSService

    var onFlip: (() -> Void)?
    var onAppearAction: (() -> Void)?

    var body: some View {
        ZStack {
            CardFace(text: frontText, pattern: "", isFront: true, currentIndex: currentIndex, totalCards: totalCards)
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))

            CardFace(text: backText, pattern: pattern, isFront: false, currentIndex: currentIndex, totalCards: totalCards)
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onTapGesture {
            UIImpactFeedbackGenerator.lightImpact()
            withAnimation(.bouncy) {
                isFlipped.toggle()
                speakCurrentText()
                onFlip?()
            }
        }
        .onAppear {
            speakCurrentText()
            onAppearAction?()
        }
    }

    private func speakCurrentText() {
        let textToSpeak = isFlipped ? backText : frontText
        ttsService.speak(textToSpeak)
    }
}

struct SwipeableCardView: View {
    let frontText: String
    let backText: String
    let pattern: String
    let currentIndex: Int
    let totalCards: Int
    @Binding var isFlipped: Bool
    @Binding var swipeOffset: CGFloat
    @Binding var showSwipeFeedback: Bool
    @Binding var swipeDirection: SessionManager.SwipeDirection?

    @EnvironmentObject private var ttsService: TTSService

    var onSwipe: ((SessionManager.SwipeDirection) -> Void)?
    var onFlip: (() -> Void)?
    var onAppearAction: (() -> Void)?

    var body: some View {
        ZStack {
            CardFace(text: frontText, pattern: "", isFront: true, currentIndex: currentIndex, totalCards: totalCards)
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))

            CardFace(text: backText, pattern: pattern, isFront: false, currentIndex: currentIndex, totalCards: totalCards)
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))

            // Swipe feedback overlay
            if showSwipeFeedback, let direction = swipeDirection {
                ZStack {
                    Color.white.opacity(0.9)
                    VStack {
                        Image(systemName: direction == .right ? "checkmark.circle.fill" : "arrow.counterclockwise.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(direction == .right ? .green : .red)
                        Text(direction == .right ? "Easy" : "Again")
                            .font(.title.bold())
                            .foregroundColor(.black)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 4)
        .offset(x: swipeOffset)
        .gesture(
            DragGesture()
                .onEnded { value in
                    let horizontalAmount = value.translation.width
                    let verticalAmount = value.translation.height
                    if abs(horizontalAmount) > abs(verticalAmount) && abs(horizontalAmount) > 50 {
                        UIImpactFeedbackGenerator.mediumImpact()
                        let direction: SessionManager.SwipeDirection = horizontalAmount > 0 ? .right : .left
                        onSwipe?(direction)
                    }
                }
        )
        .onTapGesture {
            UIImpactFeedbackGenerator.lightImpact()
            withAnimation(.bouncy) {
                isFlipped.toggle()
                speakCurrentText()
                onFlip?()
            }
        }
        .onAppear {
            speakCurrentText()
            onAppearAction?()
        }
    }

    private func speakCurrentText() {
        let textToSpeak = isFlipped ? backText : frontText
        ttsService.speak(textToSpeak)
    }
}