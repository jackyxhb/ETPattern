//
//  CardFace.swift
//  ETPattern
//
//  Extracted from SharedViews.swift for testability.
//

import SwiftUI
@preconcurrency import Translation

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
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: theme.metrics.cardFaceContentSpacing) {
                        if isFront {
                            frontContentView
                        } else {
                            backContent
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(theme.metrics.cardFacePadding)

            translationOverlay
        }
        .padding(theme.metrics.cardFaceOuterPadding)
        .onAppear {
            viewModel.setup(text: text, isFront: isFront)
        }
    }

    @ViewBuilder
    private var translationOverlay: some View {
        Color.clear
            .safeAppTranslationTask(id: viewModel.sentences.joined()) { session in
                let sentencesToTranslate = viewModel.sentences
                var newTranslations: [String: String] = [:]
                
                for sentence in sentencesToTranslate {
                    do {
                        let response = try await session.translate(sentence)
                        newTranslations[sentence] = response.targetText
                    } catch {
                        // Continue with other sentences if one fails
                    }
                }
                
                if !newTranslations.isEmpty {
                    await MainActor.run {
                        self.viewModel.updateTranslations(newTranslations)
                    }
                }
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
            .fill(theme.gradients.card)
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
            // Card ID Badge
            Text("\(cardId ?? 0)/\(max(totalCards, 1))")
                .font(.caption.monospacedDigit())
                .foregroundColor(theme.colors.textSecondary)
                .padding(.horizontal, theme.metrics.cardFaceHeaderHorizontalPadding)
                .padding(.vertical, theme.metrics.cardFaceHeaderVerticalPadding)
                .background(theme.colors.surfaceLight)
                .clipShape(Capsule())
                .dynamicTypeSize(.large ... .accessibility5)

            Spacer()

            // Group Name Badge (Always visible if present)
            if !groupName.isEmpty {
                Text(groupName)
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
                            .dynamicTypeSize(.large ... .accessibility5)
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
