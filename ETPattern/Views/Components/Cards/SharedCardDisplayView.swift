//
//  SharedCardDisplayView.swift
//  ETPattern
//
//  Extracted from SharedViews.swift for testability.
//

import SwiftUI

struct SharedCardDisplayView: View {
    let frontText: String
    let backText: String
    let groupName: String
    let cardName: String
    let isFlipped: Bool
    let currentIndex: Int
    let totalCards: Int
    let cardId: Int?
    let showSwipeFeedback: Bool
    let swipeDirection: SwipeDirection?
    let theme: Theme

    var body: some View {
        ZStack {
            CardFace(
                text: frontText,
                pattern: "",
                groupName: groupName,
                isFront: true,
                currentIndex: currentIndex,
                totalCards: totalCards,
                cardId: cardId.map { Int32($0) }
            )
            .id(frontText)
            .opacity(isFlipped ? 0 : 1)
            .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            .accessibilityHidden(isFlipped)
            .accessibilityLabel("Card front: \(frontText.isEmpty ? "No content" : frontText)")
            .accessibilityHint("Double tap to flip card and hear pronunciation")

            CardFace(
                text: backText,
                pattern: cardName,
                groupName: groupName,
                isFront: false,
                currentIndex: currentIndex,
                totalCards: totalCards,
                cardId: cardId.map { Int32($0) }
            )
            .id(backText)
            .opacity(isFlipped ? 1 : 0)
            .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
            .accessibilityHidden(!isFlipped)
            .accessibilityLabel("Card back: \(backText.isEmpty ? "No content" : backText.replacingOccurrences(of: "<br>", with: ". "))")
            .accessibilityHint("Double tap to flip card back to front")

            // Swipe feedback overlay
            if showSwipeFeedback, let direction = swipeDirection {
                ZStack {
                    theme.colors.surfaceLight
                    VStack {
                        Image(
                            systemName: direction == .right
                                ? "checkmark.circle.fill"
                                : "arrow.counterclockwise.circle.fill"
                        )
                        .font(.system(size: theme.metrics.cardDisplaySwipeIconSize))
                        .foregroundColor(
                            direction == .right ? theme.colors.success : theme.colors.danger
                        )
                        .accessibilityHidden(true)
                        Text(direction == .right ? "Easy" : "Again")
                            .font(theme.metrics.title.weight(.bold))
                            .foregroundColor(theme.colors.textPrimary)
                            .dynamicTypeSize(.large ... .accessibility5)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: theme.metrics.cardDisplaySwipeCornerRadius))
                .transition(.opacity)
                .accessibilityLabel(direction == .right ? "Marked as easy" : "Marked as again")
                .accessibilityHint("Card will be rated and next card will appear")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, theme.metrics.cardDisplayVerticalPadding)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Flashcard \(currentIndex + 1) of \(totalCards)")
        .accessibilityValue(isFlipped ? "Showing back" : "Showing front")
    }
}
