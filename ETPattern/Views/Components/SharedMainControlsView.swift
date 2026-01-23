//
//  SharedMainControlsView.swift
//  ETPattern
//
//  Created by admin on 22/12/2025.
//

import SwiftUI

struct SharedMainControlsView<MiddleContent: View>: View {
    let strategyToggleAction: () -> Void
    let previousAction: () -> Void
    let nextAction: () -> Void
    let closeAction: () -> Void
    let isPreviousDisabled: Bool
    let strategy: StudyStrategy
    let theme: Theme
    let previousHint: String?
    let nextHint: String?
    @ViewBuilder let middleContent: () -> MiddleContent

    init(
        strategyToggleAction: @escaping () -> Void,
        previousAction: @escaping () -> Void,
        nextAction: @escaping () -> Void,
        closeAction: @escaping () -> Void,
        isPreviousDisabled: Bool,
        strategy: StudyStrategy,
        theme: Theme,
        previousHint: String? = nil,
        nextHint: String? = nil,
        @ViewBuilder middleContent: @escaping () -> MiddleContent
    ) {
        self.strategyToggleAction = strategyToggleAction
        self.previousAction = previousAction
        self.nextAction = nextAction
        self.closeAction = closeAction
        self.isPreviousDisabled = isPreviousDisabled
        self.strategy = strategy
        self.theme = theme
        self.previousHint = previousHint
        self.nextHint = nextHint
        self.middleContent = middleContent
    }

    var body: some View {
        HStack(spacing: theme.metrics.sharedControlsSpacing) {
            SharedStudyStrategyButton(
                strategy: strategy,
                theme: theme,
                action: strategyToggleAction
            )
            Spacer()
            previousButton
            middleContent()
            nextButton
            Spacer()
            SharedCloseButton(
                theme: theme,
                action: closeAction
            )
        }
        .padding(.horizontal, theme.metrics.sharedControlsHorizontalPadding)
        .padding(.bottom, theme.metrics.sharedControlsBottomPadding)
        .padding(.top, theme.metrics.sharedControlsTopPadding)
    }

    private var previousButton: some View {
        Button(action: previousAction) {
            Image(systemName: "backward.end.fill")
                .font(theme.metrics.title3)
                .foregroundColor(theme.colors.textSecondary)
                .frame(width: theme.metrics.sharedControlsButtonSize, height: theme.metrics.sharedControlsButtonSize)
                .background(theme.colors.surfaceMedium)
                .clipShape(Circle())
        }
        .disabled(isPreviousDisabled)
        .opacity(isPreviousDisabled ? 0.3 : 1)
        .accessibilityLabel("Previous Card")
        .accessibilityHint(previousHint ?? (isPreviousDisabled ? "No previous card available" : "Go to previous card"))
    }

    private var nextButton: some View {
        Button(action: nextAction) {
            Image(systemName: "forward.end.fill")
                .font(theme.metrics.title3)
                .foregroundColor(theme.colors.textPrimary)
                .frame(width: theme.metrics.sharedControlsButtonSize, height: theme.metrics.sharedControlsButtonSize)
                .background(theme.gradients.success)
                .clipShape(Circle())
        }
        .accessibilityLabel("Next Card")
        .accessibilityHint(nextHint ?? "Go to next card")
    }
}