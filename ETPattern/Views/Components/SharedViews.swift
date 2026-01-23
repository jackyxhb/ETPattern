//
//  SharedViews.swift
//  ETPattern
//
//  Created by admin on 25/11/2025.
//

import SwiftUI
import Translation
import os
import Combine
import ETPatternModels

@MainActor
final class CardFaceViewModel: ObservableObject {
    @Published var translations: [String: String] = [:]
    @Published var sentences: [String] = []

    private let logger = Logger(subsystem: "com.jack.ETPattern", category: "CardFaceViewModel")

    @MainActor
    func setup(text: String, isFront: Bool) {
        if isFront {
            let separators = CharacterSet(charactersIn: ".!?\n")
            let components = text.components(separatedBy: separators)
            self.sentences = components.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        } else {
            self.sentences = text.components(separatedBy: "\n").filter { !$0.isEmpty }
        }
    }

    func performTranslation(session: TranslationSession) {
        Task {
            do {
                var newTranslations: [String: String] = [:]
                for sentence in sentences {
                    logger.info("Translating: \(sentence)")
                    let response = try await session.translate(sentence)
                    newTranslations[sentence] = response.targetText
                }
                await MainActor.run {
                    self.translations = newTranslations
                    logger.info("Translations updated: \(self.translations)")
                }
            } catch {
                logger.error("Translation error: \(error)")
            }
        }
    }
}

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

    private func splitIntoSentences(_ text: String) -> [String] {
        // Simple sentence splitting
        let separators = CharacterSet(charactersIn: ".!?\n")
        let components = text.components(separatedBy: separators)
        return components.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
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
            .id(frontText)
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
            .id(backText)
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

    // ViewModel is the Single Source of Truth
    @StateObject private var viewModel = CardFaceViewModel()

    var body: some View {
        ZStack {
            cardBackground

            VStack(alignment: .leading, spacing: theme.metrics.cardFaceContentSpacing) {
                header
                Spacer(minLength: 0)

                if isFront {
                    frontContentView
                } else {
                    backContent
                }

                Spacer(minLength: 0)
            }
            .padding(theme.metrics.cardFacePadding)
        }
        .padding(theme.metrics.cardFaceOuterPadding)
        .onAppear {
            viewModel.setup(text: text, isFront: isFront)
        }
        .safeAppTranslationTask { session in
            viewModel.performTranslation(session: session)
        }
    }

    // MARK: - Subviews

    private var frontContentView: some View {
        Group {
            if viewModel.sentences.isEmpty {
                Text("No content")
                    .font(theme.metrics.largeTitle.weight(.bold))
                    .foregroundColor(theme.colors.textPrimary)
                    .frame(maxWidth: .infinity)
            } else {
                VStack(alignment: .center, spacing: 8) {
                    ForEach(viewModel.sentences, id: \.self) { sentence in
                        VStack(alignment: .center, spacing: 4) {
                            Text(sentence)
                                .font(theme.metrics.largeTitle.weight(.bold))
                                .multilineTextAlignment(.center)
                                .foregroundColor(theme.colors.textPrimary)

                            if let translation = viewModel.translations[sentence] {
                                Text(translation)
                                    .font(theme.metrics.body.weight(.medium))
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(theme.colors.textSecondary)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: theme.metrics.cornerRadius)
            .fill(theme.gradients.card) // Keep the tint
            .background(
                RoundedRectangle(cornerRadius: theme.metrics.cornerRadius)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.metrics.cornerRadius)
                    .stroke(theme.colors.surfaceLight, lineWidth: 1.5)
            )
            .shadow(color: theme.colors.shadow, radius: theme.metrics.cardFaceShadowRadius, x: 0, y: theme.metrics.cardFaceShadowY)
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
                VStack(alignment: .leading, spacing: 6) {
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

                    if let translation = viewModel.translations[example] {
                        Text(translation)
                            .font(theme.metrics.body.weight(.medium))
                            .foregroundColor(theme.colors.textSecondary)
                            .lineSpacing(theme.metrics.cardBackLineSpacing)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .dynamicTypeSize(.large ... .accessibility5)
                    }
                }
                .padding(.horizontal, theme.metrics.cardBackHorizontalPadding)
            }
        }
    }
}

struct SharedStudyStrategyButton: View {
    let strategy: StudyStrategy
    let theme: Theme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: strategy.icon)
                .font(theme.metrics.title3)
                .foregroundColor(theme.colors.textPrimary)
                .frame(width: theme.metrics.sharedButtonSize, height: theme.metrics.sharedButtonSize)
                .background(theme.colors.surfaceLight)
                .clipShape(Circle())
        }
        .accessibilityLabel("Study Mode: \(strategy.displayName)")
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
            // Background removed to allow Liquid Glass sheet presentation


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

struct SharedThemedPicker: View {
    @Environment(\.theme) var theme
    let label: String
    let options: [String: String]
    @Binding var selection: String
    let onChange: ((String) -> Void)?
    
    @State private var isPresented = false

    var body: some View {
        Button(action: {
            isPresented = true
        }) {
            HStack {
                Text(label)
                    .foregroundColor(theme.colors.textPrimary)
                Spacer()
                Text(options[selection] ?? selection)
                    .foregroundColor(theme.colors.highlight)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $isPresented) {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(options.keys.sorted(), id: \.self) { key in
                            Button(action: {
                                selection = key
                                onChange?(key)
                                isPresented = false
                            }) {
                                HStack {
                                    Text(options[key] ?? key)
                                        .foregroundColor(theme.colors.textPrimary)
                                    Spacer()
                                    if selection == key {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(theme.colors.highlight)
                                    }
                                }
                                .padding()
                                .background(selection == key ? theme.colors.surfaceMedium : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
            .presentationDetents([.fraction(0.4), .medium])
            .presentationDragIndicator(.visible)
            .themedPresentation()
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
            SharedThemedPicker(
                label: label,
                options: options,
                selection: $selection,
                onChange: { newValue in
                    if let userDefaultsKey = userDefaultsKey {
                        UserDefaults.standard.set(newValue, forKey: userDefaultsKey)
                    } else if let onChange = onChange {
                        onChange(newValue)
                    }
                }
            )
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
            .onChange(of: value) { _, newValue in
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

struct ThemedGlassBackground: ViewModifier {
    @Environment(\.theme) var theme
    
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
    }
}

struct ThemedPresentation: ViewModifier {
    @Environment(\.theme) var theme
    
    func body(content: Content) -> some View {
        content
            .presentationBackground(.ultraThinMaterial)
            .presentationCornerRadius(theme.metrics.cornerRadius)
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

    func themedGlassBackground() -> some View {
        modifier(ThemedGlassBackground())
    }

    func themedPresentation() -> some View {
        modifier(ThemedPresentation())
    }

    @ViewBuilder
    func safeAppTranslationTask(action: @escaping (TranslationSession) -> Void) -> some View {
        #if os(iOS) && !targetEnvironment(simulator)
        self.translationTask(
            TranslationSession.Configuration(
                source: Locale.Language(identifier: "en"),
                target: Locale.Language(identifier: "zh")
            )
        ) { session in
            action(session)
        }
        #else
        self
        #endif
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
                .tabViewStyleIfiOS(.page(indexDisplayMode: .never))

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
                            #if os(iOS)
UIImpactFeedbackGenerator(style: .light).impactOccurred()
#endif
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
                            #if os(iOS)
UIImpactFeedbackGenerator(style: .light).impactOccurred()
#endif
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
                            #if os(iOS)
UINotificationFeedbackGenerator().notificationOccurred(.success)
#endif
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