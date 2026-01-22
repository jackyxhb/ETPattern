//
//  OnboardingView.swift
//  ETPattern
//
//  Created by admin on 05/12/2025.
//

import SwiftUI
import ETPatternCore

struct OnboardingView: View {
    @Environment(\.theme) var theme
    @State private var currentPage = 0
    @State private var showMainApp = false
    let onComplete: () -> Void

    var body: some View {
        let pages = [
            SharedOnboardingPageView(
                title: NSLocalizedString("welcome_title", comment: "Welcome page title"),
                subtitle: NSLocalizedString("welcome_subtitle", comment: "Welcome page subtitle"),
                description: NSLocalizedString("welcome_description", comment: "Welcome page description"),
                systemImage: "logo",
                gradient: theme.gradients.accent
            ),
            SharedOnboardingPageView(
                title: NSLocalizedString("smart_learning_title", comment: "Smart learning page title"),
                subtitle: NSLocalizedString("smart_learning_subtitle", comment: "Smart learning page subtitle"),
                description: NSLocalizedString("smart_learning_description", comment: "Smart learning page description"),
                systemImage: "brain.head.profile",
                gradient: theme.gradients.success
            ),
            SharedOnboardingPageView(
                title: NSLocalizedString("auto_play_title", comment: "Auto play page title"),
                subtitle: NSLocalizedString("auto_play_subtitle", comment: "Auto play page subtitle"),
                description: NSLocalizedString("auto_play_description", comment: "Auto play page description"),
                systemImage: "waveform",
                gradient: theme.gradients.card
            ),
            SharedOnboardingPageView(
                title: NSLocalizedString("ready_begin_title", comment: "Ready to begin page title"),
                subtitle: NSLocalizedString("ready_begin_subtitle", comment: "Ready to begin page subtitle"),
                description: NSLocalizedString("ready_begin_description", comment: "Ready to begin page description"),
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