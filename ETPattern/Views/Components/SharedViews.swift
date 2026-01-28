//
//  SharedViews.swift
//  ETPattern
//
//  Created by admin on 25/11/2025.
//
//  NOTE: This file has been decomposed for better testability.
//  The following components have been moved to separate files:
//
//  - CardFaceViewModel → ViewModels/CardFaceViewModel.swift
//  - SwipeDirection → Views/Components/Cards/SwipeDirection.swift
//  - CardFace → Views/Components/Cards/CardFace.swift
//  - SharedCardDisplayView → Views/Components/Cards/SharedCardDisplayView.swift
//  - SharedHeaderView → Views/Components/Primitives/SharedHeaderView.swift
//  - SharedProgressBarView → Views/Components/Primitives/SharedProgressBarView.swift
//  - SharedModalContainer → Views/Components/Primitives/SharedModalContainer.swift
//  - SharedThemedPicker → Views/Components/Settings/SharedThemedPicker.swift
//  - SharedSettingsPickerSection → Views/Components/Settings/SharedSettingsPickerSection.swift
//  - SharedSettingsSliderSection → Views/Components/Settings/SharedSettingsSliderSection.swift
//  - SharedOnboardingPageView → Views/Components/Onboarding/SharedOnboardingPageView.swift
//  - SharedOnboardingContainer → Views/Components/Onboarding/SharedOnboardingContainer.swift
//  - View Modifiers & Extensions → Views/Modifiers/ViewModifiers.swift
//

import SwiftUI

// MARK: - Shared Buttons

struct SharedStudyStrategyButton: View {
    let strategy: StudyStrategy
    let theme: Theme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: strategy.icon)
                .font(theme.metrics.title3)
                .foregroundColor(theme.colors.textPrimary)
                .frame(width: theme.metrics.sharedButtonSize, height: theme.metrics.sharedButtonSize)
                .background(theme.colors.surfaceLight)
                .clipShape(Circle())
        }
        .accessibilityLabel("Study Mode: \(strategy.displayName)")
    }
}

struct SharedCloseButton: View {
    let theme: Theme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(theme.metrics.title3)
                .foregroundColor(theme.colors.textPrimary)
                .frame(width: theme.metrics.sharedButtonSize, height: theme.metrics.sharedButtonSize)
                .background(theme.colors.surfaceLight)
                .clipShape(Circle())
        }
        .accessibilityLabel("Close")
    }
}