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
    let pattern: String
    let isFlipped: Bool
    let currentIndex: Int
    let totalCards: Int
    let showSwipeFeedback: Bool
    let swipeDirection: SwipeDirection?
    let theme: Theme

    var body: some View {
        ZStack {
            CardFace(
                text: frontText,
                pattern: "",
                isFront: true,
                currentIndex: currentIndex,
                totalCards: totalCards
            )
            .opacity(isFlipped ? 0 : 1)
            .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))

            CardFace(
                text: backText,
                pattern: pattern,
                isFront: false,
                currentIndex: currentIndex,
                totalCards: totalCards
            )
            .opacity(isFlipped ? 1 : 0)
            .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))

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
                        Text(direction == .right ? "Easy" : "Again")
                            .font(theme.typography.title.weight(.bold))
                            .foregroundColor(theme.colors.textPrimary)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 4)
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

            ProgressView(value: Double(currentPosition), total: Double(totalCards))
                .tint(theme.colors.highlight)
                .frame(height: 4)

            percentageText
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private var percentageText: some View {
        Text(totalCards > 0 ? "\(Int((Double(currentPosition) / Double(totalCards)) * 100))%" : "0%")
            .font(theme.typography.caption2)
            .foregroundColor(theme.colors.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(theme.colors.surfaceMedium)
            .clipShape(Capsule())
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