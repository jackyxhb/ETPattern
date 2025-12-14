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
        SwipeableCardView(
            frontText: sessionManager.currentCardIndex < sessionManager.cardsDue.count ?
                      (sessionManager.cardsDue[sessionManager.currentCardIndex].front ?? "No front") : "No front",
            backText: formatBackText(),
            pattern: sessionManager.currentCardIndex < sessionManager.cardsDue.count ?
                     (sessionManager.cardsDue[sessionManager.currentCardIndex].front ?? "") : "",
            currentIndex: sessionManager.cardsReviewedCount,
            totalCards: sessionManager.totalCardsInSession,
            isFlipped: $sessionManager.isFlipped,
            swipeOffset: $sessionManager.swipeOffset,
            showSwipeFeedback: $sessionManager.showSwipeFeedback,
            swipeDirection: $sessionManager.swipeDirection,
            onSwipe: { direction in
                sessionManager.animateSwipe(direction: direction)
            },
            onFlip: nil,
            onAppearAction: nil
        )
        .onChange(of: sessionManager.currentCardIndex) { _ in
            sessionManager.onCardChange()
        }
    }

    private func formatBackText() -> String {
        guard sessionManager.currentCardIndex < sessionManager.cardsDue.count,
              let backText = sessionManager.cardsDue[sessionManager.currentCardIndex].back else {
            return "No back"
        }
        return backText.formatCardBackText()
    }
}