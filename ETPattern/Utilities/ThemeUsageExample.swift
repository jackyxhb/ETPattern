//
//  ThemeUsageExample.swift
//  ETPattern
//
//  Created by admin on 18/12/2025.
//

import SwiftUI

struct ThemeUsageExample: View {
    @Environment(\.theme) var theme: Theme

    var body: some View {
        VStack(spacing: theme.metrics.mediumSpacing) {
            // Using theme colors
            Text("Primary Text")
                .foregroundColor(theme.colors.textPrimary)
                .font(theme.typography.title)

            Text("Secondary Text")
                .foregroundColor(theme.colors.textSecondary)
                .font(theme.typography.body)

            // Using theme gradients
            RoundedRectangle(cornerRadius: theme.metrics.cornerRadius)
                .fill(theme.gradients.accent)
                .frame(height: 50)
                .overlay(
                    Text("Accent Button")
                        .foregroundColor(theme.colors.textPrimary)
                        .font(theme.typography.headline)
                )

            // Using theme spacing and metrics
            HStack(spacing: theme.metrics.standardSpacing) {
                Circle()
                    .fill(theme.gradients.success)
                    .frame(width: 30, height: 30)

                Circle()
                    .fill(theme.gradients.danger)
                    .frame(width: 30, height: 30)

                Circle()
                    .fill(theme.gradients.warning)
                    .frame(width: 30, height: 30)
            }
            .padding(theme.metrics.largeSpacing)
            .background(theme.gradients.card)
            .clipShape(RoundedRectangle(cornerRadius: theme.metrics.cornerRadius))
        }
        .padding(theme.metrics.largeSpacing)
        .background(theme.gradients.background)
    }
}

#Preview {
    ThemeUsageExample()
        .environment(\.theme, Theme.default)
}