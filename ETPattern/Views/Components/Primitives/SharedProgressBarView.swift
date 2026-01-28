//
//  SharedProgressBarView.swift
//  ETPattern
//
//  Extracted from SharedViews.swift for testability.
//

import SwiftUI

struct SharedProgressBarView: View {
    let currentPosition: Int
    let totalCards: Int
    let theme: Theme

    var body: some View {
        HStack(spacing: theme.metrics.progressBarSpacing) {
            Text("\(currentPosition)/\(totalCards)")
                .font(theme.metrics.caption.weight(.bold))
                .foregroundColor(theme.colors.textSecondary)
                .dynamicTypeSize(.large ... .accessibility5)

            ProgressView(value: Double(currentPosition), total: Double(totalCards))
                .tint(theme.colors.highlight)
                .frame(height: theme.metrics.progressBarHeight)
                .accessibilityLabel("Study Progress")
                .accessibilityValue("\(currentPosition) of \(totalCards) cards completed")

            percentageText
        }
        .padding(.horizontal, theme.metrics.progressBarHorizontalPadding)
        .padding(.top, theme.metrics.progressBarTopPadding)
        .padding(.bottom, theme.metrics.progressBarBottomPadding)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Study Session Progress")
        .accessibilityValue("Card \(currentPosition) of \(totalCards), \(percentage)% complete")
    }

    private var percentageText: some View {
        Text(totalCards > 0 ? "\(Int((Double(currentPosition) / Double(totalCards)) * 100))%" : "0%")
            .font(theme.metrics.caption2)
            .foregroundColor(theme.colors.textSecondary)
            .padding(.horizontal, theme.metrics.progressPercentageHorizontalPadding)
            .padding(.vertical, theme.metrics.progressPercentageVerticalPadding)
            .background(theme.colors.surfaceMedium)
            .clipShape(Capsule())
            .dynamicTypeSize(.large ... .accessibility5)
            .accessibilityHidden(true)
    }

    private var percentage: Int {
        totalCards > 0 ? Int((Double(currentPosition) / Double(totalCards)) * 100) : 0
    }
}
