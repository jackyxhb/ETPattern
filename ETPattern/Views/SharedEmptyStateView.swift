//
//  SharedEmptyStateView.swift
//  ETPattern
//
//  Created by admin on 22/12/2025.
//

import SwiftUI

struct SharedEmptyStateView<IconContent: View, AdditionalContent: View>: View {
    let title: String
    let subtitle: String?
    let description: String
    let theme: Theme
    let circleSize: CGFloat
    let circleOpacity: Double
    let iconSize: CGFloat
    let verticalSpacing: CGFloat
    let textSpacing: CGFloat
    let horizontalPadding: CGFloat
    @ViewBuilder let iconContent: () -> IconContent
    @ViewBuilder let additionalContent: () -> AdditionalContent

    init(
        title: String,
        subtitle: String? = nil,
        description: String,
        theme: Theme,
        circleSize: CGFloat = 160,
        circleOpacity: Double = 0.3,
        iconSize: CGFloat = 60,
        verticalSpacing: CGFloat = 32,
        textSpacing: CGFloat = 16,
        horizontalPadding: CGFloat = 24,
        @ViewBuilder iconContent: @escaping () -> IconContent,
        @ViewBuilder additionalContent: @escaping () -> AdditionalContent = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.theme = theme
        self.circleSize = circleSize
        self.circleOpacity = circleOpacity
        self.iconSize = iconSize
        self.verticalSpacing = verticalSpacing
        self.textSpacing = textSpacing
        self.horizontalPadding = horizontalPadding
        self.iconContent = iconContent
        self.additionalContent = additionalContent
    }

    // Convenience initializer for common cases
    init(
        title: String,
        subtitle: String? = nil,
        description: String,
        icon: String,
        iconColor: Color,
        theme: Theme,
        circleSize: CGFloat = 160,
        circleOpacity: Double = 0.3,
        iconSize: CGFloat = 60,
        verticalSpacing: CGFloat = 32,
        textSpacing: CGFloat = 16,
        horizontalPadding: CGFloat = 24
    ) where IconContent == AnyView, AdditionalContent == AnyView {
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.theme = theme
        self.circleSize = circleSize
        self.circleOpacity = circleOpacity
        self.iconSize = iconSize
        self.verticalSpacing = verticalSpacing
        self.textSpacing = textSpacing
        self.horizontalPadding = horizontalPadding
        self.iconContent = {
            AnyView(
                Image(systemName: icon)
                    .font(.system(size: iconSize))
                    .foregroundColor(iconColor)
            )
        }
        self.additionalContent = { AnyView(EmptyView()) }
    }

    var body: some View {
        VStack(spacing: verticalSpacing) {
            Spacer()

            ZStack {
                Circle()
                    .fill(theme.gradients.card.opacity(circleOpacity))
                    .frame(width: circleSize, height: circleSize)

                iconContent()
            }

            VStack(spacing: textSpacing) {
                Text(title)
                    .font(theme.typography.title.weight(.bold))
                    .foregroundColor(theme.colors.textPrimary)
                    .multilineTextAlignment(.center)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(theme.typography.title3)
                        .foregroundColor(theme.colors.highlight)
                        .multilineTextAlignment(.center)
                }

                Text(description)
                    .font(theme.typography.body)
                    .foregroundColor(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }

            additionalContent()

            Spacer()
        }
        .padding(.horizontal, horizontalPadding)
    }
}

