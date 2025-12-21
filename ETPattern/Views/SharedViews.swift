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
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(theme.typography.title.weight(.bold))
                    .foregroundColor(theme.colors.textPrimary)
                Text(subtitle)
                    .font(theme.typography.subheadline)
                    .foregroundColor(theme.colors.textSecondary)
            }
            Spacer()
        }
        .padding(.horizontal, 4)
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
                        .font(.system(size: 60))
                        .foregroundColor(
                            direction == .right ? theme.colors.success : theme.colors.danger
                        )
                        .accessibilityHidden(true) // Decorative
                        Text(direction == .right ? "Easy" : "Again")
                            .font(theme.typography.title.weight(.bold))
                            .foregroundColor(theme.colors.textPrimary)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .transition(.opacity)
                .accessibilityLabel(direction == .right ? "Marked as easy" : "Marked as again")
                .accessibilityHint("Card will be rated and next card will appear")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 4)
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
        HStack(spacing: 12) {
            Text("\(currentPosition)/\(totalCards)")
                .font(theme.typography.caption.weight(.bold))
                .foregroundColor(theme.colors.textSecondary)
                .dynamicTypeSize(.large ... .accessibility5)

            ProgressView(value: Double(currentPosition), total: Double(totalCards))
                .tint(theme.colors.highlight)
                .frame(height: 4)
                .accessibilityLabel("Study Progress")
                .accessibilityValue("\(currentPosition) of \(totalCards) cards completed")

            percentageText
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Study Session Progress")
        .accessibilityValue("Card \(currentPosition) of \(totalCards), \(percentage)% complete")
    }

    private var percentageText: some View {
        Text(totalCards > 0 ? "\(Int((Double(currentPosition) / Double(totalCards)) * 100))%" : "0%")
            .font(theme.typography.caption2)
            .foregroundColor(theme.colors.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
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
                .shadow(color: theme.colors.shadow, radius: 30, x: 0, y: 30)

            VStack(alignment: .leading, spacing: 28) {
                header
                Spacer(minLength: 0)
                if isFront {
                    Text(text.isEmpty ? "No content" : text)
                        .font(theme.typography.largeTitle.weight(.bold))
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
            .padding(20)
        }
        .padding(8)
    }

    private var header: some View {
        HStack {
            if let cardId = cardId {
                Text("\(cardId)/\(max(totalCards, 1))")
                    .font(.caption.monospacedDigit())
                    .foregroundColor(theme.colors.textSecondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(theme.colors.surfaceLight)
                    .clipShape(Capsule())
            } else {
                Text("?/\(max(totalCards, 1))")
                    .font(.caption.monospacedDigit())
                    .foregroundColor(theme.colors.textSecondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(theme.colors.surfaceLight)
                    .clipShape(Capsule())
            }

            Spacer()

            if isFront && !groupName.isEmpty {
                Text(groupName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(theme.colors.highlight)
                    .lineLimit(1)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(theme.colors.surfaceMedium)
                    .clipShape(Capsule())
            } else if !isFront && !pattern.isEmpty {
                Text(pattern)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(theme.colors.highlight)
                    .lineLimit(1)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(theme.colors.surfaceMedium)
                    .clipShape(Capsule())
            }
        }
    }

    @ViewBuilder
    private var backContent: some View {
        let examples = text.components(separatedBy: "\n").filter { !$0.isEmpty }

        VStack(alignment: .leading, spacing: 18) {
            ForEach(Array(examples.enumerated()), id: \.offset) { index, example in
                HStack(alignment: .top, spacing: 12) {
                    Text(String(format: "%02d", index + 1))
                        .font(.caption.bold())
                        .foregroundColor(theme.colors.textSecondary)
                        .padding(8)
                        .background(theme.colors.surfaceLight)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    Text(example)
                        .font(theme.typography.body.weight(.medium))
                        .foregroundColor(theme.colors.textPrimary)
                        .lineSpacing(6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .dynamicTypeSize(.large ... .accessibility5) // Support dynamic type
                }
                .padding(.horizontal, 6)
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
                .font(theme.typography.title3)
                .foregroundColor(theme.colors.textPrimary)
                .frame(width: 44, height: 44)
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
                .font(theme.typography.title3)
                .foregroundColor(theme.colors.textPrimary)
                .frame(width: 44, height: 44)
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
                    .padding(10)
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
        Section(header: Text(header).foregroundColor(theme.colors.textPrimary)) {
            Picker(selection: $selection) {
                ForEach(options.keys.sorted(), id: \.self) { key in
                    Text(options[key] ?? key)
                        .foregroundColor(theme.colors.textPrimary)
                        .tag(key)
                }
            } label: {
                Text(label)
                    .foregroundColor(theme.colors.textPrimary)
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

struct SharedSettingsSliderSection: View {
    @Environment(\.theme) var theme
    let label: String
    @Binding var value: Float
    let minValue: Float
    let maxValue: Float
    let step: Float
    let minLabel: String
    let maxLabel: String
    let valueFormatter: (Float) -> String
    let onChange: (Float) -> Void

    init(label: String, value: Binding<Float>, minValue: Float, maxValue: Float, step: Float, minLabel: String, maxLabel: String, valueFormatter: @escaping (Float) -> String = { "\(Int($0))%" }, onChange: @escaping (Float) -> Void) {
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
                .font(theme.typography.subheadline)
                .foregroundColor(theme.colors.textPrimary)

            Slider(value: $value, in: minValue...maxValue, step: step) {
                Text(label)
                    .foregroundColor(theme.colors.textPrimary)
            } minimumValueLabel: {
                Text(minLabel)
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
            } maximumValueLabel: {
                Text(maxLabel)
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
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