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

// MARK: - Onboarding Components

struct SharedOnboardingPageView: View {
    @Environment(\.theme) var theme
    let title: String
    let subtitle: String
    let description: String
    let systemImage: String
    let gradient: LinearGradient

    init(title: String, subtitle: String, description: String, systemImage: String, gradient: LinearGradient) {
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.systemImage = systemImage
        self.gradient = gradient
    }

    var body: some View {
        VStack(spacing: theme.metrics.onboardingPageSpacing) {
            Spacer()

            ZStack {
                Circle()
                    .fill(gradient.opacity(0.2))
                    .frame(width: theme.metrics.onboardingCircleSize, height: theme.metrics.onboardingCircleSize)

                if systemImage == "logo" {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: theme.metrics.onboardingIconSize, height: theme.metrics.onboardingIconSize)
                        .clipShape(RoundedRectangle(cornerRadius: theme.metrics.onboardingIconSize * 0.223))
                } else {
                    Image(systemName: systemImage)
                        .font(.system(size: theme.metrics.onboardingIconSize))
                        .foregroundColor(theme.colors.textPrimary)
                }
            }
            .padding(.bottom, theme.metrics.onboardingCircleBottomPadding)

            VStack(spacing: theme.metrics.onboardingContentSpacing) {
                Text(title)
                    .font(.title.bold())
                    .foregroundColor(theme.colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .dynamicTypeSize(.large ... .accessibility5)

                Text(subtitle)
                    .font(.title3)
                    .foregroundColor(theme.colors.highlight)
                    .multilineTextAlignment(.center)
                    .dynamicTypeSize(.large ... .accessibility5)

                Text(description)
                    .font(.body)
                    .foregroundColor(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, theme.metrics.onboardingDescriptionHorizontalPadding)
                    .dynamicTypeSize(.large ... .accessibility5)
            }

            Spacer()
        }
        .padding(.horizontal, theme.metrics.onboardingPageHorizontalPadding)
    }
}

struct SharedOnboardingContainer<Content: View>: View {
    @Environment(\.theme) var theme
    let pages: [Content]
    let currentPage: Binding<Int>
    let onComplete: () -> Void

    init(pages: [Content], currentPage: Binding<Int>, onComplete: @escaping () -> Void) {
        self.pages = pages
        self.currentPage = currentPage
        self.onComplete = onComplete
    }

    var body: some View {
        ZStack {
            theme.gradients.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        pages[index]
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Custom page indicators
                HStack(spacing: theme.metrics.onboardingIndicatorSpacing) {
                    ForEach(pages.indices, id: \.self) { index in
                        Circle()
                            .fill(currentPage.wrappedValue == index ? theme.colors.highlight : theme.colors.surfaceMedium)
                            .frame(width: theme.metrics.onboardingIndicatorSize, height: theme.metrics.onboardingIndicatorSize)
                            .animation(.smooth, value: currentPage.wrappedValue)
                    }
                }
                .padding(.vertical, theme.metrics.onboardingIndicatorVerticalPadding)

                // Navigation buttons
                HStack(spacing: theme.metrics.onboardingButtonSpacing) {
                    if currentPage.wrappedValue > 0 {
                        Button(action: {
                            UIImpactFeedbackGenerator.lightImpact()
                            withAnimation(.smooth) {
                                currentPage.wrappedValue -= 1
                            }
                        }) {
                            Text("Back")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                                .frame(width: theme.metrics.onboardingBackButtonWidth, height: theme.metrics.onboardingButtonHeight)
                                .dynamicTypeSize(.large ... .accessibility5)
                        }
                    }

                    Spacer()

                    if currentPage.wrappedValue < pages.count - 1 {
                        Button(action: {
                            UIImpactFeedbackGenerator.lightImpact()
                            withAnimation(.smooth) {
                                currentPage.wrappedValue += 1
                            }
                        }) {
                            Text("Next")
                                .font(.headline.bold())
                                .foregroundColor(theme.colors.textPrimary)
                                .frame(width: theme.metrics.onboardingNextButtonWidth, height: theme.metrics.onboardingButtonHeight)
                                .background(theme.gradients.accent)
                                .clipShape(RoundedRectangle(cornerRadius: theme.metrics.onboardingButtonCornerRadius, style: .continuous))
                                .dynamicTypeSize(.large ... .accessibility5)
                        }
                    } else {
                        Button(action: {
                            UINotificationFeedbackGenerator.success()
                            withAnimation(.bouncy) {
                                onComplete()
                            }
                        }) {
                            Text("Get Started")
                                .font(.headline.bold())
                                .foregroundColor(theme.colors.textPrimary)
                                .frame(width: theme.metrics.onboardingGetStartedButtonWidth, height: theme.metrics.onboardingButtonHeight)
                                .background(theme.gradients.success)
                                .clipShape(RoundedRectangle(cornerRadius: theme.metrics.onboardingButtonCornerRadius, style: .continuous))
                                .dynamicTypeSize(.large ... .accessibility5)
                        }
                    }
                }
                .padding(.horizontal, theme.metrics.onboardingContainerHorizontalPadding)
                .padding(.bottom, theme.metrics.onboardingContainerBottomPadding)
            }
        }
    }
}