//
//  OnboardingView.swift
//  ETPattern
//
//  Created by admin on 05/12/2025.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.theme) var theme
    @State private var currentPage = 0
    @State private var showMainApp = false
    let onComplete: () -> Void

    var body: some View {
        let pages = [
            OnboardingPage(
                title: "Welcome to English Thought",
                subtitle: "Master 300 English expression patterns",
                description: "Learn natural English expressions with our comprehensive flashcard system featuring automatic text-to-speech.",
                systemImage: "sparkles",
                gradient: theme.gradients.accent
            ),
            OnboardingPage(
                title: "Smart Learning",
                subtitle: "Spaced repetition made simple",
                description: "Our algorithm helps you review cards at optimal intervals, ensuring you remember patterns long-term.",
                systemImage: "brain.head.profile",
                gradient: theme.gradients.success
            ),
            OnboardingPage(
                title: "Auto-Play Mode",
                subtitle: "Hands-free learning experience",
                description: "Let the app automatically play through your cards with natural speech. Perfect for passive learning.",
                systemImage: "waveform",
                gradient: theme.gradients.card
            ),
            OnboardingPage(
                title: "Ready to Begin",
                subtitle: "Your English journey starts now",
                description: "Import your CSV files or start with our built-in 300 pattern deck. Happy learning!",
                systemImage: "checkmark.circle.fill",
                gradient: theme.gradients.accent
            )
        ]

        ZStack {
            theme.gradients.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Custom page indicators
                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? theme.colors.highlight : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.smooth, value: currentPage)
                    }
                }
                .padding(.vertical, 20)

                // Navigation buttons
                HStack(spacing: 16) {
                    if currentPage > 0 {
                        Button(action: {
                            UIImpactFeedbackGenerator.lightImpact()
                            withAnimation(.smooth) {
                                currentPage -= 1
                            }
                        }) {
                            Text("Back")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                                .frame(width: 80, height: 50)
                        }
                    }

                    Spacer()

                    if currentPage < pages.count - 1 {
                        Button(action: {
                            UIImpactFeedbackGenerator.lightImpact()
                            withAnimation(.smooth) {
                                currentPage += 1
                            }
                        }) {
                            Text("Next")
                                .font(.headline.bold())
                                .foregroundColor(theme.colors.textPrimary)
                                .frame(width: 80, height: 50)
                                .background(theme.gradients.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
                                .frame(width: 140, height: 50)
                                .background(theme.gradients.success)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

struct OnboardingPage: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let description: String
    let systemImage: String
    let gradient: LinearGradient
}

struct OnboardingPageView: View {
    @Environment(\.theme) var theme
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(page.gradient.opacity(0.2))
                    .frame(width: 200, height: 200)

                Image(systemName: page.systemImage)
                    .font(.system(size: 80))
                    .foregroundColor(theme.colors.textPrimary)
            }
            .padding(.bottom, 20)

            VStack(spacing: 16) {
                Text(page.title)
                    .font(.title.bold())
                    .foregroundColor(theme.colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.title3)
                    .foregroundColor(theme.colors.highlight)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.body)
                    .foregroundColor(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

#Preview {
    OnboardingView(onComplete: {})
}