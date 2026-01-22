//
//  Theme.swift
//  ETPattern
//
//  Created by admin on 18/12/2025.
//

import SwiftUI
import ETPatternCore

public struct Theme {
    public let gradients: Gradients
    public let colors: Colors
    public let metrics: Metrics

    public nonisolated(unsafe) static let dark = Theme(
        gradients: Gradients(),
        colors: Colors(),
        metrics: Metrics()
    )

    public nonisolated(unsafe) static let light = Theme(
        gradients: Gradients(
            background: LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.95, green: 0.95, blue: 0.97),
                    Color(red: 0.92, green: 0.92, blue: 0.95),
                    Color(red: 0.90, green: 0.90, blue: 0.93)
                ]),
                startPoint: .top,
                endPoint: .bottom
            ),
            card: LinearGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.7),
                    Color.white.opacity(0.5)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        ),
        colors: Colors(
            background: Color(red: 0.95, green: 0.95, blue: 0.97),
            onBackground: Color.black,
            surface: Color.white.opacity(0.7),
            onSurface: Color.black,
            surfaceVariant: Color.black.opacity(0.05),
            onSurfaceVariant: Color.black.opacity(0.8),
            surfaceElevated: Color.white.opacity(0.95),
            onSurfaceElevated: Color.black,
            outline: Color.black.opacity(0.1),
            backgroundStart: Color(red: 0.95, green: 0.95, blue: 0.97),
            backgroundEnd: Color(red: 0.90, green: 0.90, blue: 0.93),
            surfaceLight: Color.white.opacity(0.8),
            surfaceMedium: Color.white.opacity(0.6),
            shadow: Color.black.opacity(0.1), // Much lighter shadow for light mode
            textPrimary: Color.black,
            textSecondary: Color.black.opacity(0.7)
        ),
        metrics: Metrics()
    )

    public struct Gradients {
        public var background = LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.05, green: 0.05, blue: 0.15),
                Color(red: 0.1, green: 0.1, blue: 0.2),
                Color(red: 0.15, green: 0.15, blue: 0.25)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )

        public var card = LinearGradient(
            gradient: Gradient(colors: [
                Color.white.opacity(0.1),
                Color.white.opacity(0.05)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )

        public var accent = LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.3, green: 0.6, blue: 1.0),
                Color(red: 0.2, green: 0.5, blue: 0.9)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )

        public var success = LinearGradient(
            gradient: Gradient(colors: [
                Color.green.opacity(0.8),
                Color.green.opacity(0.6)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )

        public var danger = LinearGradient(
            gradient: Gradient(colors: [
                Color.red.opacity(0.8),
                Color.red.opacity(0.6)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )

        public var warning = LinearGradient(
            gradient: Gradient(colors: [
                Color.orange.opacity(0.8),
                Color.orange.opacity(0.6)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )

        public var neutral = LinearGradient(
            gradient: Gradient(colors: [
                Color.teal.opacity(0.8),
                Color.teal.opacity(0.6)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    public struct Colors {
        // Background colors
        public var background = Color(red: 0.05, green: 0.05, blue: 0.15)
        public var onBackground = Color.white

        // Surface colors (elevated)
        public var surface = Color.white.opacity(0.1)
        public var onSurface = Color.white
        public var surfaceVariant = Color.white.opacity(0.05)
        public var onSurfaceVariant = Color.white.opacity(0.8)

        // Elevated surface for menus/popovers
        public var surfaceElevated = Color.white.opacity(0.95)
        public var onSurfaceElevated = Color.black.opacity(0.8)

        // Outline/border
        public var outline = Color.white.opacity(0.2)

        // Legacy colors (keeping for compatibility)
        public var backgroundStart = Color(red: 0.05, green: 0.05, blue: 0.15)
        public var backgroundEnd = Color(red: 0.15, green: 0.15, blue: 0.25)
        public var highlight = Color(red: 0.3, green: 0.6, blue: 1.0)
        public var surfaceLight = Color.white.opacity(0.15)
        public var surfaceMedium = Color.white.opacity(0.1)
        public var shadow = Color.black.opacity(0.3)
        public var textPrimary = Color.white
        public var textSecondary = Color.white.opacity(0.7)
        public var success = Color.green
        public var warning = Color.orange
        public var danger = Color.red
    }

    public struct Metrics {
        public let cornerRadius: CGFloat = 20.0
        public let shadowRadius: CGFloat = 14.0
        public let shadowY: CGFloat = 10.0
        public let standardSpacing: CGFloat = 8.0
        public let smallSpacing: CGFloat = 4.0
        public let mediumSpacing: CGFloat = 16.0
        public let largeSpacing: CGFloat = 24.0
        public let buttonPadding: CGFloat = 16.0
        public let sliderHeight: CGFloat = 44.0
        
        // ContentView specific metrics
        public let contentHorizontalPadding: CGFloat = 16.0
        public let contentTopPadding: CGFloat = 20.0
        public let mainContentSpacing: CGFloat = 16.0
        
        // Empty state metrics
        public let emptyStateCircleSize: CGFloat = 120.0
        public let emptyStateCircleOpacity: CGFloat = 0.2
        public let emptyStateVerticalSpacing: CGFloat = 24.0
        public let emptyStateTextSpacing: CGFloat = 12.0
        public let emptyStateHorizontalPadding: CGFloat = 0.0
        public let emptyStateIconSize: CGFloat = 60.0
        public let emptyStateButtonHorizontalPadding: CGFloat = 32.0
        public let emptyStateButtonVerticalPadding: CGFloat = 16.0
        public let emptyStateButtonTopPadding: CGFloat = 20.0
        public let emptyStateVerticalPadding: CGFloat = 60.0
        public let emptyStateButtonSpacing: CGFloat = 16.0
        public let emptyStateButtonCornerRadius: CGFloat = 16.0
        
        // CardSetActionBar metrics
        public let actionBarButtonSpacing: CGFloat = 8.0
        public let actionBarHorizontalPadding: CGFloat = 6.0
        public let actionBarVerticalPadding: CGFloat = 6.0
        public let actionBarCornerRadius: CGFloat = 24.0
        public let actionBarContainerHorizontalPadding: CGFloat = 16.0
        
        // ActionButton metrics
        public let actionButtonVerticalPadding: CGFloat = 10.0
        public let actionButtonCornerRadius: CGFloat = 16.0
        
        // DeckListView metrics
        public let deckListSpacing: CGFloat = 14.0
        public let deckCardVerticalPadding: CGFloat = 16.0
        public let deckCardHorizontalPadding: CGFloat = 18.0
        public let deckCardBottomPadding: CGFloat = 120.0
        
        // SharedViews metrics
        public let sharedHeaderSpacing: CGFloat = 6.0
        public let sharedHeaderHorizontalPadding: CGFloat = 4.0
        
        // SharedCardDisplayView metrics
        public let cardDisplaySwipeIconSize: CGFloat = 60.0
        public let cardDisplaySwipeCornerRadius: CGFloat = 24.0
        public let cardDisplayVerticalPadding: CGFloat = 4.0
        
        // SharedProgressBarView metrics
        public let progressBarSpacing: CGFloat = 12.0
        public let progressBarHeight: CGFloat = 4.0
        public let progressBarHorizontalPadding: CGFloat = 20.0
        public let progressBarTopPadding: CGFloat = 16.0
        public let progressBarBottomPadding: CGFloat = 8.0
        public let progressPercentageHorizontalPadding: CGFloat = 8.0
        public let progressPercentageVerticalPadding: CGFloat = 4.0
        
        // CardFace metrics
        public let cardFaceHeaderHorizontalPadding: CGFloat = 14.0
        public let cardFaceHeaderVerticalPadding: CGFloat = 8.0
        public let cardFaceContentSpacing: CGFloat = 28.0
        public let cardFacePadding: CGFloat = 20.0
        public let cardFaceOuterPadding: CGFloat = 8.0
        public let cardFaceShadowRadius: CGFloat = 30.0
        public let cardFaceShadowY: CGFloat = 30.0
        
        // CardFace back content metrics
        public let cardBackContentSpacing: CGFloat = 18.0
        public let cardBackItemSpacing: CGFloat = 12.0
        public let cardBackNumberPadding: CGFloat = 8.0
        public let cardBackNumberCornerRadius: CGFloat = 10.0
        public let cardBackLineSpacing: CGFloat = 6.0
        public let cardBackHorizontalPadding: CGFloat = 6.0
        
        // Shared button metrics
        public let sharedButtonSize: CGFloat = 44.0
        
        // SharedModalContainer metrics
        public let modalCloseButtonPadding: CGFloat = 10.0
        
        // SharedOnboardingPageView metrics
        public let onboardingCircleSize: CGFloat = 200.0
        public let onboardingIconSize: CGFloat = 80.0
        public let onboardingCircleBottomPadding: CGFloat = 20.0
        public let onboardingContentSpacing: CGFloat = 16.0
        public let onboardingDescriptionHorizontalPadding: CGFloat = 32.0
        public let onboardingPageSpacing: CGFloat = 32.0
        public let onboardingPageHorizontalPadding: CGFloat = 24.0
        
        // SharedOnboardingContainer metrics
        public let onboardingIndicatorSpacing: CGFloat = 8.0
        public let onboardingIndicatorSize: CGFloat = 8.0
        public let onboardingIndicatorVerticalPadding: CGFloat = 20.0
        public let onboardingButtonSpacing: CGFloat = 16.0
        public let onboardingBackButtonWidth: CGFloat = 80.0
        public let onboardingNextButtonWidth: CGFloat = 80.0
        public let onboardingGetStartedButtonWidth: CGFloat = 140.0
        public let onboardingButtonHeight: CGFloat = 50.0
        public let onboardingButtonCornerRadius: CGFloat = 16.0
        public let onboardingContainerHorizontalPadding: CGFloat = 24.0
        public let onboardingContainerBottomPadding: CGFloat = 40.0
        
        // StudyView metrics
        public let studyViewSpacing: CGFloat = 8.0
        public let studyViewHorizontalPadding: CGFloat = 4.0
        public let studySpeakButtonSize: CGFloat = 60.0
        
        // AutoPlayView metrics
        public let autoPlayViewSpacing: CGFloat = 8.0
        public let autoPlayViewHorizontalPadding: CGFloat = 4.0
        public let autoPlayButtonSize: CGFloat = 60.0
        public let autoPlayButtonShadowRadius: CGFloat = 8.0
        public let autoPlayButtonShadowY: CGFloat = 4.0
        public let autoPlayFallbackFrontDelay: TimeInterval = 1.0
        public let autoPlayFallbackBackDelay: TimeInterval = 1.5
        public let autoPlayInterCardDelay: TimeInterval = 1.0
        
        // DeckDetailView metrics
        public let deckDetailGroupSpacing: CGFloat = 4.0
        public let deckDetailCardSpacing: CGFloat = 12.0
        public let deckDetailLeadingPadding: CGFloat = 16.0
        public let deckDetailGroupPadding: CGFloat = 16.0
        public let deckDetailScrollPadding: CGFloat = 16.0
        public let deckDetailCardRowSpacing: CGFloat = 8.0
        public let deckDetailCardRowPadding: CGFloat = 16.0
        public let deckDetailCardShadowRadius: CGFloat = 12.0
        public let deckDetailCardShadowY: CGFloat = 8.0
        public let deckDetailPreviewHorizontalPadding: CGFloat = 16.0
        
        // SplashView metrics
        public let splashSpacing: CGFloat = 18.0
        public let splashLogoSize: CGFloat = 180.0
        public let splashShadowRadius: CGFloat = 30.0
        public let splashShadowY: CGFloat = 16.0
        public let splashPadding: CGFloat = 32.0
        
        // ProgressCircle metrics
        public let progressCircleLineWidth: CGFloat = 8.0
        public let progressCircleSize: CGFloat = 60.0
        public let progressCircleFontSize: CGFloat = 14.0
        
        // SharedMainControlsView metrics
        public let sharedControlsSpacing: CGFloat = 16.0
        public let sharedControlsHorizontalPadding: CGFloat = 20.0
        public let sharedControlsBottomPadding: CGFloat = 8.0
        public let sharedControlsTopPadding: CGFloat = 8.0
        public let sharedControlsButtonSize: CGFloat = 44.0
        
        // HeaderView metrics
        public let headerIconPadding: CGFloat = 10.0
        public let headerMainSpacing: CGFloat = 12.0
        
        // DeckListView additional metrics
        public let deckCardInnerSpacing: CGFloat = 10.0
        public let deckCardTextSpacing: CGFloat = 4.0
        
        // ImportView metrics
        public let importHeaderVerticalPadding: CGFloat = 12.0
        
        // Animation and timing metrics
        public let splashFadeOutDuration: TimeInterval = 0.3
        public let splashTransitionDuration: TimeInterval = 0.4
        public let splashDisplayDuration: TimeInterval = 0.1
        
        // Preview spacing metrics
        public let previewSpacing: CGFloat = 20.0
        
        // SharedEmptyStateView default metrics
        public let emptyStateDefaultCircleSize: CGFloat = 160.0
        public let emptyStateDefaultCircleOpacity: Double = 0.3
        public let emptyStateDefaultIconSize: CGFloat = 60.0
        public let emptyStateDefaultVerticalSpacing: CGFloat = 32.0
        public let emptyStateDefaultTextSpacing: CGFloat = 16.0
        public let emptyStateDefaultHorizontalPadding: CGFloat = 24.0
        
        // Card metrics (from Constants)
        public let cardCornerRadius: CGFloat = 12.0
        public let cardPadding: CGFloat = 20.0
        
        // General animation duration
        public let animationDuration: TimeInterval = 0.6
        
        // Chart metrics
        public let chartBarCornerRadius: CGFloat = 6.0

        public let headline = Font.headline
        public let subheadline = Font.subheadline
        public let body = Font.body
        public let caption = Font.caption
        public let caption2 = Font.caption2
        public let title = Font.title
        public let title2 = Font.title2
        public let title3 = Font.title3
        public let largeTitle = Font.largeTitle

        public init() {}
    }
}

public struct ThemeKey: EnvironmentKey {
    public nonisolated(unsafe) static let defaultValue: Theme = Theme.dark
}

extension EnvironmentValues {
    public var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

extension View {
    public func withTheme(_ theme: Theme) -> some View {
        environment(\.theme, theme)
    }
}