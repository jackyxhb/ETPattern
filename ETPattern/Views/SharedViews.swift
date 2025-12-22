//
//  SharedViews.swift
//  ETPattern
//
//  Created by admin on 25/11/2025.
//

import SwiftUI

enum SwipeDirection {
    case left, right
}

struct SharedHeaderView: View {
    let title: String
    let subtitle: String
    let theme: Theme

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: theme.metrics.sharedHeaderSpacing) {
                Text(title)
                    .font(theme.metrics.title.weight(.bold))
                    .foregroundColor(theme.colors.textPrimary)
                Text(subtitle)
                    .font(theme.metrics.subheadline)
                    .foregroundColor(theme.colors.textSecondary)
            }
            Spacer()
        }
        .padding(.horizontal, theme.metrics.sharedHeaderHorizontalPadding)
    }
}

struct SharedCardDisplayView: View {
    let frontText: String
    let backText: String
    let groupName: String
    let cardName: String
    let isFlipped: Bool
    let currentIndex: Int
    let totalCards: Int
    let cardId: Int?
    let showSwipeFeedback: Bool
    let swipeDirection: SwipeDirection?
    let theme: Theme

    var body: some View {
        ZStack {
            CardFace(
                text: frontText,
                pattern: "",
                groupName: groupName,
                isFront: true,
                currentIndex: currentIndex,
                totalCards: totalCards,
                cardId: cardId.map { Int32($0) }
            )
            .opacity(isFlipped ? 0 : 1)
            .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            .accessibilityHidden(isFlipped) // Hide front when flipped
            .accessibilityLabel("Card front: \(frontText.isEmpty ? "No content" : frontText)")
            .accessibilityHint("Double tap to flip card and hear pronunciation")

            CardFace(
                text: backText,
                pattern: cardName,
                groupName: groupName,
                isFront: false,
                currentIndex: currentIndex,
                totalCards: totalCards,
                cardId: cardId.map { Int32($0) }
            )
            .opacity(isFlipped ? 1 : 0)
            .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
            .accessibilityHidden(!isFlipped) // Hide back when not flipped
            .accessibilityLabel("Card back: \(backText.isEmpty ? "No content" : backText.replacingOccurrences(of: "<br>", with: ". "))")
            .accessibilityHint("Double tap to flip card back to front")

            // Swipe feedback overlay
            if showSwipeFeedback, let direction = swipeDirection {
                ZStack {
                    theme.colors.surfaceLight
                    VStack {
                        Image(
                            systemName: direction == .right
                                ? "checkmark.circle.fill"
                                : "arrow.counterclockwise.circle.fill"
                        )
                        .font(.system(size: theme.metrics.cardDisplaySwipeIconSize))
                        .foregroundColor(
                            direction == .right ? theme.colors.success : theme.colors.danger
                        )
                        .accessibilityHidden(true) // Decorative
                        Text(direction == .right ? "Easy" : "Again")
                            .font(theme.metrics.title.weight(.bold))
                            .foregroundColor(theme.colors.textPrimary)
                            .dynamicTypeSize(.large ... .accessibility5)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: theme.metrics.cardDisplaySwipeCornerRadius))
                .transition(.opacity)
                .accessibilityLabel(direction == .right ? "Marked as easy" : "Marked as again")
                .accessibilityHint("Card will be rated and next card will appear")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, theme.metrics.cardDisplayVerticalPadding)
        .accessibilityElement(children: .contain) // Group card elements together
        .accessibilityLabel("Flashcard \(currentIndex + 1) of \(totalCards)")
        .accessibilityValue(isFlipped ? "Showing back" : "Showing front")
    }
}

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
            .accessibilityHidden(true) // Already included in parent accessibility value
    }

    private var percentage: Int {
        totalCards > 0 ? Int((Double(currentPosition) / Double(totalCards)) * 100) : 0
    }
}

struct CardFace: View {
    let text: String
    let pattern: String
    let groupName: String
    let isFront: Bool
    let currentIndex: Int
    let totalCards: Int
    let cardId: Int32?

    @Environment(\.theme) var theme

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: theme.metrics.cornerRadius)
                .fill(theme.gradients.card)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.metrics.cornerRadius)
                        .stroke(theme.colors.surfaceLight, lineWidth: 1.5)
                )
                .shadow(color: theme.colors.shadow, radius: theme.metrics.cardFaceShadowRadius, x: 0, y: theme.metrics.cardFaceShadowY)

            VStack(alignment: .leading, spacing: theme.metrics.cardFaceContentSpacing) {
                header
                Spacer(minLength: 0)
                if isFront {
                    Text(text.isEmpty ? "No content" : text)
                        .font(theme.metrics.largeTitle.weight(.bold))
                        .multilineTextAlignment(.center)
                        .foregroundColor(theme.colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .minimumScaleFactor(0.5)
                        .lineLimit(3)
                        .dynamicTypeSize(.large ... .accessibility5) // Support dynamic type
                } else {
                    backContent
                }
                Spacer(minLength: 0)
            }
            .padding(theme.metrics.cardFacePadding)
        }
        .padding(theme.metrics.cardFaceOuterPadding)
    }

    private var header: some View {
        HStack {
            if let cardId = cardId {
                Text("\(cardId)/\(max(totalCards, 1))")
                    .font(.caption.monospacedDigit())
                    .foregroundColor(theme.colors.textSecondary)
                    .padding(.horizontal, theme.metrics.cardFaceHeaderHorizontalPadding)
                    .padding(.vertical, theme.metrics.cardFaceHeaderVerticalPadding)
                    .background(theme.colors.surfaceLight)
                    .clipShape(Capsule())
                    .dynamicTypeSize(.large ... .accessibility5)
            } else {
                Text("?/\(max(totalCards, 1))")
                    .font(.caption.monospacedDigit())
                    .foregroundColor(theme.colors.textSecondary)
                    .padding(.horizontal, theme.metrics.cardFaceHeaderHorizontalPadding)
                    .padding(.vertical, theme.metrics.cardFaceHeaderVerticalPadding)
                    .background(theme.colors.surfaceLight)
                    .clipShape(Capsule())
                    .dynamicTypeSize(.large ... .accessibility5)
            }

            Spacer()

            if isFront && !groupName.isEmpty {
                Text(groupName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(theme.colors.highlight)
                    .lineLimit(1)
                    .padding(.horizontal, theme.metrics.cardFaceHeaderHorizontalPadding)
                    .padding(.vertical, theme.metrics.cardFaceHeaderVerticalPadding)
                    .background(theme.colors.surfaceMedium)
                    .clipShape(Capsule())
                    .dynamicTypeSize(.large ... .accessibility5)
            } else if !isFront && !pattern.isEmpty {
                Text(pattern)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(theme.colors.highlight)
                    .lineLimit(1)
                    .padding(.horizontal, theme.metrics.cardFaceHeaderHorizontalPadding)
                    .padding(.vertical, theme.metrics.cardFaceHeaderVerticalPadding)
                    .background(theme.colors.surfaceMedium)
                    .clipShape(Capsule())
                    .dynamicTypeSize(.large ... .accessibility5)
            }
        }
    }

    @ViewBuilder
    private var backContent: some View {
        let examples = text.components(separatedBy: "\n").filter { !$0.isEmpty }

        VStack(alignment: .leading, spacing: theme.metrics.cardBackContentSpacing) {
            ForEach(Array(examples.enumerated()), id: \.offset) { index, example in
                HStack(alignment: .top, spacing: theme.metrics.cardBackItemSpacing) {
                    Text(String(format: "%02d", index + 1))
                        .font(.caption.bold())
                        .foregroundColor(theme.colors.textSecondary)
                        .padding(theme.metrics.cardBackNumberPadding)
                        .background(theme.colors.surfaceLight)
                        .clipShape(RoundedRectangle(cornerRadius: theme.metrics.cardBackNumberCornerRadius, style: .continuous))
                        .dynamicTypeSize(.large ... .accessibility5)

                    Text(example)
                        .font(theme.metrics.body.weight(.medium))
                        .foregroundColor(theme.colors.textPrimary)
                        .lineSpacing(theme.metrics.cardBackLineSpacing)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .dynamicTypeSize(.large ... .accessibility5) // Support dynamic type
                }
                .padding(.horizontal, theme.metrics.cardBackHorizontalPadding)
            }
        }
    }
}

struct SharedOrderToggleButton: View {
    let isRandomOrder: Bool
    let theme: Theme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isRandomOrder ? "shuffle" : "arrow.up.arrow.down")
                .font(theme.metrics.title3)
                .foregroundColor(theme.colors.textPrimary)
                .frame(width: theme.metrics.sharedButtonSize, height: theme.metrics.sharedButtonSize)
                .background(theme.colors.surfaceLight)
                .clipShape(Circle())
        }
        .accessibilityLabel(isRandomOrder ? "Random Order" : "Sequential Order")
    }
}

struct SharedCloseButton: View {
    let theme: Theme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(theme.metrics.title3)
                .foregroundColor(theme.colors.textPrimary)
                .frame(width: theme.metrics.sharedButtonSize, height: theme.metrics.sharedButtonSize)
                .background(theme.colors.surfaceLight)
                .clipShape(Circle())
        }
        .accessibilityLabel("Close")
    }
}

struct SharedModalContainer<Content: View>: View {
    @Environment(\.theme) var theme
    let content: Content
    let onClose: () -> Void

    init(onClose: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.onClose = onClose
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            theme.gradients.background
                .ignoresSafeArea()

            content

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundColor(theme.colors.textPrimary)
                    .padding(theme.metrics.modalCloseButtonPadding)
                    .background(theme.colors.textPrimary.opacity(0.2), in: Circle())
                    .padding()
            }
            .accessibilityLabel("Close")
        }
    }
}

struct SharedSettingsPickerSection: View {
    @Environment(\.theme) var theme
    let header: String
    let label: String
    let options: [String: String]
    @Binding var selection: String
    let userDefaultsKey: String?
    let onChange: ((String) -> Void)?

    init(header: String, label: String, options: [String: String], selection: Binding<String>, userDefaultsKey: String) {
        self.header = header
        self.label = label
        self.options = options
        self._selection = selection
        self.userDefaultsKey = userDefaultsKey
        self.onChange = nil
    }

    init(header: String, label: String, options: [String: String], selection: Binding<String>, onChange: @escaping (String) -> Void) {
        self.header = header
        self.label = label
        self.options = options
        self._selection = selection
        self.userDefaultsKey = nil
        self.onChange = onChange
    }

    var body: some View {
        Section(header: Text(header).foregroundColor(theme.colors.textPrimary).dynamicTypeSize(.large ... .accessibility5)) {
            Picker(selection: $selection) {
                ForEach(options.keys.sorted(), id: \.self) { key in
                    Text(options[key] ?? key)
                        .foregroundColor(theme.colors.textPrimary)
                        .dynamicTypeSize(.large ... .accessibility5)
                        .tag(key)
                }
            } label: {
                Text(label)
                    .foregroundColor(theme.colors.textPrimary)
                    .dynamicTypeSize(.large ... .accessibility5)
            }
            .pickerStyle(.menu)
            .onChange(of: selection) { newValue in
                if let userDefaultsKey = userDefaultsKey {
                    UserDefaults.standard.set(newValue, forKey: userDefaultsKey)
                } else if let onChange = onChange {
                    onChange(newValue)
                }
            }
        }
        .listRowBackground(theme.colors.surfaceLight)
    }
}

struct SharedSettingsSliderSection<T: BinaryFloatingPoint>: View {
    @Environment(\.theme) var theme
    let label: String
    @Binding var value: T
    let minValue: T
    let maxValue: T
    let step: T
    let minLabel: String
    let maxLabel: String
    let valueFormatter: (T) -> String
    let onChange: (T) -> Void

    init(label: String, value: Binding<T>, minValue: T, maxValue: T, step: T, minLabel: String, maxLabel: String, valueFormatter: @escaping (T) -> String = { "\($0)" }, onChange: @escaping (T) -> Void) {
        self.label = label
        self._value = value
        self.minValue = minValue
        self.maxValue = maxValue
        self.step = step
        self.minLabel = minLabel
        self.maxLabel = maxLabel
        self.valueFormatter = valueFormatter
        self.onChange = onChange
    }

    var body: some View {
        VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
            Text("\(label): \(valueFormatter(value))")
                .font(theme.metrics.subheadline)
                .foregroundColor(theme.colors.textPrimary)
                .dynamicTypeSize(.large ... .accessibility5)

            Slider(value: Binding(
                get: { Double(value) },
                set: { value = T($0) }
            ), in: Double(minValue)...Double(maxValue), step: Double(step)) {
                Text(label)
                    .foregroundColor(theme.colors.textPrimary)
                    .dynamicTypeSize(.large ... .accessibility5)
            } minimumValueLabel: {
                Text(minLabel)
                    .font(theme.metrics.caption)
                    .foregroundColor(theme.colors.textSecondary)
                    .dynamicTypeSize(.large ... .accessibility5)
            } maximumValueLabel: {
                Text(maxLabel)
                    .font(theme.metrics.caption)
                    .foregroundColor(theme.colors.textSecondary)
                    .dynamicTypeSize(.large ... .accessibility5)
            }
            .tint(theme.colors.highlight)
            .onChange(of: value) { newValue in
                onChange(newValue)
            }
        }
        .padding(.vertical, theme.metrics.smallSpacing)
        .listRowBackground(theme.colors.surfaceLight)
    }
}

// MARK: - Alert Components

struct SharedConfirmationAlert: ViewModifier {
    @Environment(\.theme) var theme
    let title: String
    let message: String
    let actionTitle: String
    let isPresented: Binding<Bool>
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .alert(title, isPresented: isPresented) {
                Button("Cancel", role: .cancel) { }
                Button(actionTitle, action: action)
            } message: {
                Text(message)
                    .dynamicTypeSize(.large ... .accessibility5)
            }
    }
}

struct SharedErrorAlert: ViewModifier {
    @Environment(\.theme) var theme
    let title: String
    let message: String
    let isPresented: Binding<Bool>

    func body(content: Content) -> some View {
        content
            .alert(title, isPresented: isPresented) {
                Button("OK") { }
            } message: {
                Text(message)
                    .dynamicTypeSize(.large ... .accessibility5)
            }
    }
}

// MARK: - View Extensions for Easy Alert Usage

extension View {
    func confirmationAlert(
        title: String,
        message: String,
        actionTitle: String,
        isPresented: Binding<Bool>,
        action: @escaping () -> Void
    ) -> some View {
        modifier(SharedConfirmationAlert(
            title: title,
            message: message,
            actionTitle: actionTitle,
            isPresented: isPresented,
            action: action
        ))
    }

    func errorAlert(
        title: String,
        message: String,
        isPresented: Binding<Bool>
    ) -> some View {
        modifier(SharedErrorAlert(
            title: title,
            message: message,
            isPresented: isPresented
        ))
    }
}

// MARK: - Onboarding Components

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

                Image(systemName: systemImage)
                    .font(.system(size: theme.metrics.onboardingIconSize))
                    .foregroundColor(theme.colors.textPrimary)
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
                            UIImpactFeedbackGenerator.lightImpact()
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
                            UIImpactFeedbackGenerator.lightImpact()
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