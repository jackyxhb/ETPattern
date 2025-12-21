//
//  OnboardingView.swift
//  ETPattern
//
//  Created by admin on 05/12/2025.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.theme) var theme
    @State private var currentPage = 0
    @State private var showMainApp = false
    let onComplete: () -> Void

    var body: some View {
        let pages = [
            SharedOnboardingPageView(
                title: "Welcome to English Thought",
                subtitle: "Master 300 English expression patterns",
                description: "Learn natural English expressions with our comprehensive flashcard system featuring automatic text-to-speech.",
                systemImage: "sparkles",
                gradient: theme.gradients.accent
            ),
            SharedOnboardingPageView(
                title: "Smart Learning",
                subtitle: "Spaced repetition made simple",
                description: "Our algorithm helps you review cards at optimal intervals, ensuring you remember patterns long-term.",
                systemImage: "brain.head.profile",
                gradient: theme.gradients.success
            ),
            SharedOnboardingPageView(
                title: "Auto-Play Mode",
                subtitle: "Hands-free learning experience",
                description: "Let the app automatically play through your cards with natural speech. Perfect for passive learning.",
                systemImage: "waveform",
                gradient: theme.gradients.card
            ),
            SharedOnboardingPageView(
                title: "Ready to Begin",
                subtitle: "Your English journey starts now",
                description: "Import your CSV files or start with our built-in 300 pattern deck. Happy learning!",
                systemImage: "checkmark.circle.fill",
                gradient: theme.gradients.accent
            )
        ]

        SharedOnboardingContainer(
            pages: pages,
            currentPage: $currentPage,
            onComplete: onComplete
        )
    }
}

#Preview {
    OnboardingView(onComplete: {})
}