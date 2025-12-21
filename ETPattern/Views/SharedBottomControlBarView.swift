//
//  SharedBottomControlBarView.swift
//  ETPattern
//
//  Created by admin on 22/12/2025.
//

import SwiftUI

struct SharedBottomControlBarView<MiddleContent: View>: View {
    let orderToggleAction: () -> Void
    let previousAction: () -> Void
    let nextAction: () -> Void
    let closeAction: () -> Void
    let isPreviousDisabled: Bool
    let isRandomOrder: Bool
    let currentPosition: Int
    let totalCards: Int
    let theme: Theme
    let previousHint: String?
    let nextHint: String?
    @ViewBuilder let middleContent: () -> MiddleContent

    init(
        orderToggleAction: @escaping () -> Void,
        previousAction: @escaping () -> Void,
        nextAction: @escaping () -> Void,
        closeAction: @escaping () -> Void,
        isPreviousDisabled: Bool,
        isRandomOrder: Bool,
        currentPosition: Int,
        totalCards: Int,
        theme: Theme,
        previousHint: String? = nil,
        nextHint: String? = nil,
        @ViewBuilder middleContent: @escaping () -> MiddleContent
    ) {
        self.orderToggleAction = orderToggleAction
        self.previousAction = previousAction
        self.nextAction = nextAction
        self.closeAction = closeAction
        self.isPreviousDisabled = isPreviousDisabled
        self.isRandomOrder = isRandomOrder
        self.currentPosition = currentPosition
        self.totalCards = totalCards
        self.theme = theme
        self.previousHint = previousHint
        self.nextHint = nextHint
        self.middleContent = middleContent
    }

    var body: some View {
        VStack(spacing: 0) {
            progressBarView
            mainControlsView
        }
        .background(theme.colors.surface)
        .buttonStyle(.plain)
    }

    private var progressBarView: some View {
        SharedProgressBarView(
            currentPosition: currentPosition,
            totalCards: totalCards,
            theme: theme
        )
    }

    private var mainControlsView: some View {
        SharedMainControlsView(
            orderToggleAction: orderToggleAction,
            previousAction: previousAction,
            nextAction: nextAction,
            closeAction: closeAction,
            isPreviousDisabled: isPreviousDisabled,
            isRandomOrder: isRandomOrder,
            theme: theme,
            previousHint: previousHint,
            nextHint: nextHint,
            middleContent: middleContent
        )
    }
}