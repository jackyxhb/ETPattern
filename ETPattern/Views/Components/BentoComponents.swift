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
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
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
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                content
            }
            .padding(16)
        }
    }
}

struct BentoRow<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        HStack(spacing: 12) {
            content
        }
    }
}

// MARK: - Study Components

struct LiquidCard: View {
    let front: String
    let back: String
    let isFlipped: Bool
    let onTap: () -> Void
    
    var body: some View {
        ZStack {
            // Back Face (Answer)
            CardContent(text: back, isFront: false)
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            
            // Front Face (Question)
            CardContent(text: front, isFront: true)
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

private struct CardContent: View {
    let text: String
    let isFront: Bool
    
    var body: some View {
        VStack {
            if isFront {
                 Text("Question")
                    .font(.caption)
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                 Text("Answer")
                    .font(.caption)
                    .textCase(.uppercase)
                    .foregroundStyle(.green)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Spacer()
            
            Text(text)
                .font(.system(size: 28, weight: .medium, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
            
            Spacer()
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .liquidGlass()
    }
}

struct LiquidControls: View {
    let onRate: (DifficultyRating) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            RatingButton(title: "Again", color: .red) { onRate(.again) }
            RatingButton(title: "Hard", color: .orange) { onRate(.hard) }
            RatingButton(title: "Good", color: .green) { onRate(.good) }
            RatingButton(title: "Easy", color: .blue) { onRate(.easy) }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

private struct RatingButton: View {
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator.snap()
            action()
        }) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(color.gradient)
                .clipShape(Capsule())
        }
    }
}
