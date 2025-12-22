//
//  Theme.swift
//  ETPattern
//
//  Created by admin on 18/12/2025.
//

import SwiftUI

struct Theme {
    let gradients: Gradients
    let colors: Colors
    let metrics: Metrics

    static let `default` = Theme(
        gradients: Gradients(),
        colors: Colors(),
        metrics: Metrics()
    )

    struct Gradients {
        let background = LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.05, green: 0.05, blue: 0.15),
                Color(red: 0.1, green: 0.1, blue: 0.2),
                Color(red: 0.15, green: 0.15, blue: 0.25)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )

        let card = LinearGradient(
            gradient: Gradient(colors: [
                Color.white.opacity(0.1),
                Color.white.opacity(0.05)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )

        let accent = LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.3, green: 0.6, blue: 1.0),
                Color(red: 0.2, green: 0.5, blue: 0.9)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )

        let success = LinearGradient(
            gradient: Gradient(colors: [
                Color.green.opacity(0.8),
                Color.green.opacity(0.6)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )

        let danger = LinearGradient(
            gradient: Gradient(colors: [
                Color.red.opacity(0.8),
                Color.red.opacity(0.6)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )

        let warning = LinearGradient(
            gradient: Gradient(colors: [
                Color.orange.opacity(0.8),
                Color.orange.opacity(0.6)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )

        let neutral = LinearGradient(
            gradient: Gradient(colors: [
                Color.teal.opacity(0.8),
                Color.teal.opacity(0.6)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    struct Colors {
        // Background colors
        let background = Color(red: 0.05, green: 0.05, blue: 0.15)
        let onBackground = Color.white

        // Surface colors (elevated)
        let surface = Color.white.opacity(0.1)
        let onSurface = Color.white
        let surfaceVariant = Color.white.opacity(0.05)
        let onSurfaceVariant = Color.white.opacity(0.8)

        // Elevated surface for menus/popovers
        let surfaceElevated = Color.white.opacity(0.95)
        let onSurfaceElevated = Color.black.opacity(0.8)

        // Outline/border
        let outline = Color.white.opacity(0.2)

        // Legacy colors (keeping for compatibility)
        let backgroundStart = Color(red: 0.05, green: 0.05, blue: 0.15)
        let backgroundEnd = Color(red: 0.15, green: 0.15, blue: 0.25)
        let highlight = Color(red: 0.3, green: 0.6, blue: 1.0)
        let surfaceLight = Color.white.opacity(0.15)
        let surfaceMedium = Color.white.opacity(0.1)
        let shadow = Color.black.opacity(0.3)
        let textPrimary = Color.white
        let textSecondary = Color.white.opacity(0.7)
        let success = Color.green
        let warning = Color.orange
        let danger = Color.red
    }

    struct Metrics {
        let cornerRadius: CGFloat = 20.0
        let shadowRadius: CGFloat = 14.0
        let shadowY: CGFloat = 10.0
        let standardSpacing: CGFloat = 8.0
        let smallSpacing: CGFloat = 4.0
        let mediumSpacing: CGFloat = 16.0
        let largeSpacing: CGFloat = 24.0
        let buttonPadding: CGFloat = 16.0
        let sliderHeight: CGFloat = 44.0
        
        // ContentView specific metrics
        let contentHorizontalPadding: CGFloat = 16.0
        let contentTopPadding: CGFloat = 20.0
        let mainContentSpacing: CGFloat = 16.0
        
        // Empty state metrics
        let emptyStateCircleSize: CGFloat = 120.0
        let emptyStateCircleOpacity: CGFloat = 0.2
        let emptyStateVerticalSpacing: CGFloat = 24.0
        let emptyStateTextSpacing: CGFloat = 12.0
        let emptyStateHorizontalPadding: CGFloat = 0.0
        let emptyStateIconSize: CGFloat = 60.0
        let emptyStateButtonHorizontalPadding: CGFloat = 32.0
        let emptyStateButtonVerticalPadding: CGFloat = 16.0
        let emptyStateButtonTopPadding: CGFloat = 20.0
        let emptyStateVerticalPadding: CGFloat = 60.0
        let emptyStateButtonSpacing: CGFloat = 16.0
        let emptyStateButtonCornerRadius: CGFloat = 16.0
        
        // CardSetActionBar metrics
        let actionBarButtonSpacing: CGFloat = 8.0
        let actionBarHorizontalPadding: CGFloat = 6.0
        let actionBarVerticalPadding: CGFloat = 6.0
        let actionBarCornerRadius: CGFloat = 24.0
        let actionBarContainerHorizontalPadding: CGFloat = 16.0
        
        // ActionButton metrics
        let actionButtonVerticalPadding: CGFloat = 10.0
        let actionButtonCornerRadius: CGFloat = 16.0
        
        // DeckListView metrics
        let deckListSpacing: CGFloat = 14.0
        let deckCardVerticalPadding: CGFloat = 16.0
        let deckCardHorizontalPadding: CGFloat = 18.0
        let deckCardBottomPadding: CGFloat = 120.0
        
        // SharedViews metrics
        let sharedHeaderSpacing: CGFloat = 6.0
        let sharedHeaderHorizontalPadding: CGFloat = 4.0
        
        // SharedCardDisplayView metrics
        let cardDisplaySwipeIconSize: CGFloat = 60.0
        let cardDisplaySwipeCornerRadius: CGFloat = 24.0
        let cardDisplayVerticalPadding: CGFloat = 4.0
        
        // SharedProgressBarView metrics
        let progressBarSpacing: CGFloat = 12.0
        let progressBarHeight: CGFloat = 4.0
        let progressBarHorizontalPadding: CGFloat = 20.0
        let progressBarTopPadding: CGFloat = 16.0
        let progressBarBottomPadding: CGFloat = 8.0
        let progressPercentageHorizontalPadding: CGFloat = 8.0
        let progressPercentageVerticalPadding: CGFloat = 4.0
        
        // CardFace metrics
        let cardFaceHeaderHorizontalPadding: CGFloat = 14.0
        let cardFaceHeaderVerticalPadding: CGFloat = 8.0
        let cardFaceContentSpacing: CGFloat = 28.0
        let cardFacePadding: CGFloat = 20.0
        let cardFaceOuterPadding: CGFloat = 8.0
        let cardFaceShadowRadius: CGFloat = 30.0
        let cardFaceShadowY: CGFloat = 30.0
        
        // CardFace back content metrics
        let cardBackContentSpacing: CGFloat = 18.0
        let cardBackItemSpacing: CGFloat = 12.0
        let cardBackNumberPadding: CGFloat = 8.0
        let cardBackNumberCornerRadius: CGFloat = 10.0
        let cardBackLineSpacing: CGFloat = 6.0
        let cardBackHorizontalPadding: CGFloat = 6.0
        
        // Shared button metrics
        let sharedButtonSize: CGFloat = 44.0
        
        // SharedModalContainer metrics
        let modalCloseButtonPadding: CGFloat = 10.0
        
        // SharedOnboardingPageView metrics
        let onboardingCircleSize: CGFloat = 200.0
        let onboardingIconSize: CGFloat = 80.0
        let onboardingCircleBottomPadding: CGFloat = 20.0
        let onboardingContentSpacing: CGFloat = 16.0
        let onboardingDescriptionHorizontalPadding: CGFloat = 32.0
        let onboardingPageSpacing: CGFloat = 32.0
        let onboardingPageHorizontalPadding: CGFloat = 24.0
        
        // SharedOnboardingContainer metrics
        let onboardingIndicatorSpacing: CGFloat = 8.0
        let onboardingIndicatorSize: CGFloat = 8.0
        let onboardingIndicatorVerticalPadding: CGFloat = 20.0
        let onboardingButtonSpacing: CGFloat = 16.0
        let onboardingBackButtonWidth: CGFloat = 80.0
        let onboardingNextButtonWidth: CGFloat = 80.0
        let onboardingGetStartedButtonWidth: CGFloat = 140.0
        let onboardingButtonHeight: CGFloat = 50.0
        let onboardingButtonCornerRadius: CGFloat = 16.0
        let onboardingContainerHorizontalPadding: CGFloat = 24.0
        let onboardingContainerBottomPadding: CGFloat = 40.0
        
        // StudyView metrics
        let studyViewSpacing: CGFloat = 8.0
        let studyViewHorizontalPadding: CGFloat = 4.0
        let studySpeakButtonSize: CGFloat = 60.0
        
        // AutoPlayView metrics
        let autoPlayViewSpacing: CGFloat = 8.0
        let autoPlayViewHorizontalPadding: CGFloat = 4.0
        let autoPlayButtonSize: CGFloat = 60.0
        let autoPlayButtonShadowRadius: CGFloat = 8.0
        let autoPlayButtonShadowY: CGFloat = 4.0
        let autoPlayFallbackFrontDelay: TimeInterval = 1.0
        let autoPlayFallbackBackDelay: TimeInterval = 1.5
        let autoPlayInterCardDelay: TimeInterval = 1.0
        
        // DeckDetailView metrics
        let deckDetailGroupSpacing: CGFloat = 4.0
        let deckDetailCardSpacing: CGFloat = 12.0
        let deckDetailLeadingPadding: CGFloat = 16.0
        let deckDetailGroupPadding: CGFloat = 16.0
        let deckDetailScrollPadding: CGFloat = 16.0
        let deckDetailCardRowSpacing: CGFloat = 8.0
        let deckDetailCardRowPadding: CGFloat = 16.0
        let deckDetailCardShadowRadius: CGFloat = 12.0
        let deckDetailCardShadowY: CGFloat = 8.0
        let deckDetailPreviewHorizontalPadding: CGFloat = 16.0
        
        // SplashView metrics
        let splashSpacing: CGFloat = 18.0
        let splashLogoSize: CGFloat = 180.0
        let splashShadowRadius: CGFloat = 30.0
        let splashShadowY: CGFloat = 16.0
        let splashPadding: CGFloat = 32.0
        
        // ProgressCircle metrics
        let progressCircleLineWidth: CGFloat = 8.0
        let progressCircleSize: CGFloat = 60.0
        let progressCircleFontSize: CGFloat = 14.0
        
        // SharedMainControlsView metrics
        let sharedControlsSpacing: CGFloat = 16.0
        let sharedControlsHorizontalPadding: CGFloat = 20.0
        let sharedControlsBottomPadding: CGFloat = 8.0
        let sharedControlsTopPadding: CGFloat = 8.0
        let sharedControlsButtonSize: CGFloat = 44.0
        
        // HeaderView metrics
        let headerIconPadding: CGFloat = 10.0
        let headerMainSpacing: CGFloat = 12.0
        
        // DeckListView additional metrics
        let deckCardInnerSpacing: CGFloat = 10.0
        let deckCardTextSpacing: CGFloat = 4.0

        let headline = Font.headline
        let subheadline = Font.subheadline
        let body = Font.body
        let caption = Font.caption
        let caption2 = Font.caption2
        let title = Font.title
        let title2 = Font.title2
        let title3 = Font.title3
        let largeTitle = Font.largeTitle
    }
}

private struct ThemeKey: EnvironmentKey {
    static let defaultValue: Theme = Theme.default
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

extension View {
    func theme(_ theme: Theme) -> some View {
        environment(\.theme, theme)
    }
}