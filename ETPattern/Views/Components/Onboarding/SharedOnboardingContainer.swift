//
//  SharedOnboardingContainer.swift
//  ETPattern
//
//  Extracted from SharedViews.swift for testability.
//

import SwiftUI

struct SharedOnboardingContainer<Content: View>: View {
    @Environment(\.theme) var theme
    let pages: [Content]
    let currentPage: Binding<Int>
    let onComplete: () -> Void

    init(pages: [Content], currentPage: Binding<Int>, onComplete: @escaping () -> Void) {
        self.pages = pages
        self.currentPage = currentPage
        self.onComplete = onComplete
    }

    var body: some View {
        ZStack {
            theme.gradients.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        pages[index]
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Custom page indicators
                HStack(spacing: theme.metrics.onboardingIndicatorSpacing) {
                    ForEach(pages.indices, id: \.self) { index in
                        Circle()
                            .fill(currentPage.wrappedValue == index ? theme.colors.highlight : theme.colors.surfaceMedium)
                            .frame(width: theme.metrics.onboardingIndicatorSize, height: theme.metrics.onboardingIndicatorSize)
                            .animation(.smooth, value: currentPage.wrappedValue)
                    }
                }
                .padding(.vertical, theme.metrics.onboardingIndicatorVerticalPadding)

                // Navigation buttons
                HStack(spacing: theme.metrics.onboardingButtonSpacing) {
                    if currentPage.wrappedValue > 0 {
                        Button(action: {
                            UIImpactFeedbackGenerator.snap()
                            withAnimation(.smooth) {
                                currentPage.wrappedValue -= 1
                            }
                        }) {
                            Text("Back")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                                .frame(width: theme.metrics.onboardingBackButtonWidth, height: theme.metrics.onboardingButtonHeight)
                                .dynamicTypeSize(.large ... .accessibility5)
                        }
                    }

                    Spacer()

                    if currentPage.wrappedValue < pages.count - 1 {
                        Button(action: {
                            UIImpactFeedbackGenerator.snap()
                            withAnimation(.smooth) {
                                currentPage.wrappedValue += 1
                            }
                        }) {
                            Text("Next")
                                .font(.headline.bold())
                                .foregroundColor(theme.colors.textPrimary)
                                .frame(width: theme.metrics.onboardingNextButtonWidth, height: theme.metrics.onboardingButtonHeight)
                                .background(theme.gradients.accent)
                                .clipShape(RoundedRectangle(cornerRadius: theme.metrics.onboardingButtonCornerRadius, style: .continuous))
                                .dynamicTypeSize(.large ... .accessibility5)
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
                                .frame(width: theme.metrics.onboardingGetStartedButtonWidth, height: theme.metrics.onboardingButtonHeight)
                                .background(theme.gradients.success)
                                .clipShape(RoundedRectangle(cornerRadius: theme.metrics.onboardingButtonCornerRadius, style: .continuous))
                                .dynamicTypeSize(.large ... .accessibility5)
                        }
                    }
                }
                .padding(.horizontal, theme.metrics.onboardingContainerHorizontalPadding)
                .padding(.bottom, theme.metrics.onboardingContainerBottomPadding)
            }
        }
    }
}
