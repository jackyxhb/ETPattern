//
//  SharedViews.swift
//  ETPattern
//
//  Created by admin on 25/11/2025.
//

import SwiftUI

enum SwipeDirection {
    case left, right
}

struct SharedHeaderView: View {
    let title: String
    let subtitle: String
    let theme: Theme

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(theme.typography.title.weight(.bold))
                    .foregroundColor(theme.colors.textPrimary)
                Text(subtitle)
                    .font(theme.typography.subheadline)
                    .foregroundColor(theme.colors.textSecondary)
            }
            Spacer()
        }
        .padding(.horizontal, 4)
    }
}

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
            .opacity(isFlipped ? 0 : 1)
            .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            .accessibilityHidden(isFlipped) // Hide front when flipped
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
            .opacity(isFlipped ? 1 : 0)
            .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
            .accessibilityHidden(!isFlipped) // Hide back when not flipped
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
                        .font(.system(size: 60))
                        .foregroundColor(
                            direction == .right ? theme.colors.success : theme.colors.danger
                        )
                        .accessibilityHidden(true) // Decorative
                        Text(direction == .right ? "Easy" : "Again")
                            .font(theme.typography.title.weight(.bold))
                            .foregroundColor(theme.colors.textPrimary)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .transition(.opacity)
                .accessibilityLabel(direction == .right ? "Marked as easy" : "Marked as again")
                .accessibilityHint("Card will be rated and next card will appear")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 4)
        .accessibilityElement(children: .contain) // Group card elements together
        .accessibilityLabel("Flashcard \(currentIndex + 1) of \(totalCards)")
        .accessibilityValue(isFlipped ? "Showing back" : "Showing front")
    }
}

struct SharedProgressBarView: View {
    let currentPosition: Int
    let totalCards: Int
    let theme: Theme

    var body: some View {
        HStack(spacing: 12) {
            Text("\(currentPosition)/\(totalCards)")
                .font(theme.typography.caption.weight(.bold))
                .foregroundColor(theme.colors.textSecondary)
                .dynamicTypeSize(.large ... .accessibility5)

            ProgressView(value: Double(currentPosition), total: Double(totalCards))
                .tint(theme.colors.highlight)
                .frame(height: 4)
                .accessibilityLabel("Study Progress")
                .accessibilityValue("\(currentPosition) of \(totalCards) cards completed")

            percentageText
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Study Session Progress")
        .accessibilityValue("Card \(currentPosition) of \(totalCards), \(percentage)% complete")
    }

    private var percentageText: some View {
        Text(totalCards > 0 ? "\(Int((Double(currentPosition) / Double(totalCards)) * 100))%" : "0%")
            .font(theme.typography.caption2)
            .foregroundColor(theme.colors.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(theme.colors.surfaceMedium)
            .clipShape(Capsule())
            .dynamicTypeSize(.large ... .accessibility5)
            .accessibilityHidden(true) // Already included in parent accessibility value
    }

    private var percentage: Int {
        totalCards > 0 ? Int((Double(currentPosition) / Double(totalCards)) * 100) : 0
    }
}

struct CardFace: View {
    let text: String
    let pattern: String
    let groupName: String
    let isFront: Bool
    let currentIndex: Int
    let totalCards: Int
    let cardId: Int32?

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
                        .font(theme.typography.largeTitle.weight(.bold))
                        .multilineTextAlignment(.center)
                        .foregroundColor(theme.colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .minimumScaleFactor(0.5)
                        .lineLimit(3)
                        .dynamicTypeSize(.large ... .accessibility5) // Support dynamic type
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
            if let cardId = cardId {
                Text("\(cardId)/\(max(totalCards, 1))")
                    .font(.caption.monospacedDigit())
                    .foregroundColor(theme.colors.textSecondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(theme.colors.surfaceLight)
                    .clipShape(Capsule())
            } else {
                Text("?/\(max(totalCards, 1))")
                    .font(.caption.monospacedDigit())
                    .foregroundColor(theme.colors.textSecondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(theme.colors.surfaceLight)
                    .clipShape(Capsule())
            }

            Spacer()

            if isFront && !groupName.isEmpty {
                Text(groupName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(theme.colors.highlight)
                    .lineLimit(1)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(theme.colors.surfaceMedium)
                    .clipShape(Capsule())
            } else if !isFront && !pattern.isEmpty {
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
                        .font(theme.typography.body.weight(.medium))
                        .foregroundColor(theme.colors.textPrimary)
                        .lineSpacing(6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .dynamicTypeSize(.large ... .accessibility5) // Support dynamic type
                }
                .padding(.horizontal, 6)
            }
        }
    }
}

struct SharedOrderToggleButton: View {
    let isRandomOrder: Bool
    let theme: Theme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isRandomOrder ? "shuffle" : "arrow.up.arrow.down")
                .font(theme.typography.title3)
                .foregroundColor(theme.colors.textPrimary)
                .frame(width: 44, height: 44)
                .background(theme.colors.surfaceLight)
                .clipShape(Circle())
        }
        .accessibilityLabel(isRandomOrder ? "Random Order" : "Sequential Order")
    }
}

struct SharedCloseButton: View {
    let theme: Theme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(theme.typography.title3)
                .foregroundColor(theme.colors.textPrimary)
                .frame(width: 44, height: 44)
                .background(theme.colors.surfaceLight)
                .clipShape(Circle())
        }
        .accessibilityLabel("Close")
    }
}