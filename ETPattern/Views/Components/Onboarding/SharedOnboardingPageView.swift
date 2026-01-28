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

        VStack(spacing: 32) {
            Spacer()
            
            // Icon / Hero
            ZStack {
                // Glow effect
                Circle()
                    .fill(gradient.opacity(0.3))
                    .blur(radius: 30)
                    .frame(width: 140, height: 140)
                    
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 10)

                if systemImage == "logo" {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                } else {
                    Image(systemName: systemImage)
                        .font(.system(size: 50))
                        .foregroundStyle(gradient)
                        .symbolEffect(.bounce, value: true) // iOS 17 animation
                }
            }
            .padding(.bottom, 20)

            VStack(spacing: 16) {
                Text(title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(theme.colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(gradient)
                    .multilineTextAlignment(.center)

                Text(description)
                    .font(.body)
                    .foregroundColor(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .lineSpacing(4)
            }
            .padding(24)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 32))
            .overlay(
                RoundedRectangle(cornerRadius: 32)
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            )
            .padding(.horizontal, 20)

            Spacer()
        }
    }

}
