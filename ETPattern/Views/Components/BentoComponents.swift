//
//  BentoComponents.swift
//  ETPattern
//
//  Created by admin on 28/01/2026.
//

import SwiftUI

// MARK: - Modifiers

struct LiquidGlassModifier: ViewModifier {
    @Environment(\.theme) var theme

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: theme.metrics.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: theme.metrics.cornerRadius, style: .continuous)
                    .stroke(theme.colors.outline, lineWidth: 0.5)
            )
            .shadow(color: theme.colors.shadow.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

extension View {
    func liquidGlass() -> some View {
        self.modifier(LiquidGlassModifier())
    }
    
    func bentoTile() -> some View {
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .liquidGlass()
    }
}

// MARK: - Components

struct BentoGrid<Content: View>: View {
    let content: Content
    @Environment(\.theme) var theme
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: theme.metrics.bentoSpacing) {
                content
            }
            .padding(theme.metrics.bentoPadding)
        }
    }
}

struct BentoRow<Content: View>: View {
    let content: Content
    @Environment(\.theme) var theme
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        HStack(spacing: theme.metrics.bentoSpacing) {
            content
        }
    }
}

// MARK: - Study Components

struct LiquidCard: View {
    let front: String
    let back: String
    let cardID: Int32?
    let groupName: String?
    let isFlipped: Bool
    let totalCards: Int
    let onTap: () -> Void
    
    var body: some View {
        ZStack {
            // Back Face (Answer)
            CardFace(
                text: back,
                pattern: "",
                groupName: groupName ?? "",
                isFront: false,
                currentIndex: 0,
                totalCards: totalCards,
                cardId: cardID
            )
            .opacity(isFlipped ? 1 : 0)
            .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            
            // Front Face (Question)
            CardFace(
                text: front,
                pattern: "",
                groupName: groupName ?? "",
                isFront: true,
                currentIndex: 0,
                totalCards: totalCards,
                cardId: cardID
            )
            .opacity(isFlipped ? 0 : 1)
        }
        .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isFlipped)
        .onTapGesture {
            UIImpactFeedbackGenerator.snap()
            onTap()
        }
    }
}

struct LiquidControls: View {
    let onRate: (DifficultyRating) -> Void
    @Environment(\.theme) var theme
    
    var body: some View {
        HStack(spacing: theme.metrics.ratingBarSpacing) {
            RatingButton(title: "Again", color: .red) { onRate(.again) }
            RatingButton(title: "Hard", color: .orange) { onRate(.hard) }
            RatingButton(title: "Good", color: .green) { onRate(.good) }
            RatingButton(title: "Easy", color: .blue) { onRate(.easy) }
        }
        .padding(theme.metrics.ratingBarPadding)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: theme.metrics.ratingBarCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: theme.metrics.ratingBarCornerRadius)
                .stroke(.white.opacity(0.1), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.1), radius: theme.metrics.ratingBarShadowRadius, x: 0, y: theme.metrics.ratingBarShadowY)
    }
}

private struct RatingButton: View {
    let title: String
    let color: Color
    let action: () -> Void
    @Environment(\.theme) var theme
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator.snap()
            action()
        }) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .padding(.vertical, theme.metrics.ratingButtonVerticalPadding)
                .padding(.horizontal, theme.metrics.ratingButtonHorizontalPadding)
                .background(color.gradient)
                .clipShape(Capsule())
        }
    }
}
