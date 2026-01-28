//
//  SharedOnboardingPageView.swift
//  ETPattern
//
//  Extracted from SharedViews.swift for testability.
//

import SwiftUI

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
