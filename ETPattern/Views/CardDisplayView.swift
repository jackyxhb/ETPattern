//
//  CardDisplayView.swift
//  ETPattern
//
//  Created by admin on 15/12/2025.
//

import SwiftUI

struct CardDisplayView: View {
    @ObservedObject var sessionManager: SessionManager

    var body: some View {
        ZStack {
            CardFace(
                text: sessionManager.currentCardIndex < sessionManager.cardsDue.count ?
                      (sessionManager.cardsDue[sessionManager.currentCardIndex].front ?? "No front") : "No front",
                pattern: "",
                isFront: true,
                currentIndex: sessionManager.cardsReviewedCount,
                totalCards: sessionManager.totalCardsInSession
            )
            .opacity(sessionManager.isFlipped ? 0 : 1)
            .rotation3DEffect(.degrees(sessionManager.isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))

            CardFace(
                text: formatBackText(),
                pattern: sessionManager.currentCardIndex < sessionManager.cardsDue.count ?
                         (sessionManager.cardsDue[sessionManager.currentCardIndex].front ?? "") : "",
                isFront: false,
                currentIndex: sessionManager.cardsReviewedCount,
                totalCards: sessionManager.totalCardsInSession
            )
            .opacity(sessionManager.isFlipped ? 1 : 0)
            .rotation3DEffect(.degrees(sessionManager.isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))

            // Swipe feedback overlay
            if sessionManager.showSwipeFeedback, let direction = sessionManager.swipeDirection {
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
        .offset(x: sessionManager.swipeOffset)
        .gesture(
            DragGesture()
                .onEnded { value in
                    let horizontalAmount = value.translation.width
                    let verticalAmount = value.translation.height
                    if abs(horizontalAmount) > abs(verticalAmount) && abs(horizontalAmount) > 50 {
                        UIImpactFeedbackGenerator.mediumImpact()
                        let direction: SessionManager.SwipeDirection = horizontalAmount > 0 ? .right : .left
                        sessionManager.animateSwipe(direction: direction)
                    }
                }
        )
        .onTapGesture {
            UIImpactFeedbackGenerator.lightImpact()
            sessionManager.flipCard()
        }
        .onAppear {
            sessionManager.speakCurrentText()
        }
        .onChange(of: sessionManager.currentCardIndex) { _ in
            sessionManager.onCardChange()
        }
    }

    private func formatBackText() -> String {
        guard sessionManager.currentCardIndex < sessionManager.cardsDue.count,
              let backText = sessionManager.cardsDue[sessionManager.currentCardIndex].back else {
            return "No back"
        }
        return backText.replacingOccurrences(of: "<br>", with: "\n")
    }
}