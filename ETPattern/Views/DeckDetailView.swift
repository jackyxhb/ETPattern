//
//  DeckDetailView.swift
//  ETPattern
//
//  Created by admin on 25/11/2025.
//

import SwiftUI
import CoreData
import UIKit

struct DeckDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) var theme

    let cardSet: CardSet

    @State private var previewCard: Card?

    var body: some View {
        ZStack {
            theme.gradients.background
                .ignoresSafeArea()

            if sortedGroupNames.isEmpty {
                Text("No cards in this deck")
                    .font(.headline)
                    .foregroundColor(theme.colors.textSecondary)
            } else {
                ScrollView {
                    LazyVStack(spacing: theme.metrics.deckDetailGroupSpacing) {
                        ForEach(sortedGroupNames, id: \.self) { groupName in
                            DisclosureGroup {
                                LazyVStack(spacing: theme.metrics.deckDetailCardSpacing) {
                                    ForEach(groupedCards[groupName] ?? []) { card in
                                        Button {
                                            previewCard = card
                                        } label: {
                                            CardRow(card: card)
                                        }
                                        .buttonStyle(.plain)
                                        .contextMenu {
                                            Button {
                                                previewCard = card
                                            } label: {
                                                Label("Preview", systemImage: "eye")
                                            }
                                        }
                                    }
                                }
                                .padding(.leading, theme.metrics.deckDetailLeadingPadding)
                            } label: {
                                HStack {
                                    Text(groupName)
                                        .font(.headline)
                                        .foregroundColor(theme.colors.textPrimary)
                                    Spacer()
                                    Text("\(groupedCards[groupName]?.count ?? 0) cards")
                                        .font(.subheadline)
                                        .foregroundColor(theme.colors.textSecondary)
                                }
                                .padding(theme.metrics.deckDetailGroupPadding)
                                .background(
                                    RoundedRectangle(cornerRadius: theme.metrics.cornerRadius)
                                        .fill(theme.gradients.card.opacity(0.9))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: theme.metrics.cornerRadius)
                                        .stroke(theme.colors.surfaceLight, lineWidth: 1)
                                )
                            }
                            .tint(.white)
                        }
                    }
                    .padding(theme.metrics.deckDetailScrollPadding)
                }
            }
        }
        .navigationTitle(cardSet.name ?? "Unnamed Deck")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $previewCard) { card in
            let allCards = sortedGroupNames.flatMap { groupedCards[$0] ?? [] }
            let index = allCards.firstIndex(where: { $0.objectID == card.objectID }) ?? 0
            CardPreviewContainer(card: card, index: index, total: allCards.count) {
                previewCard = nil
            }
        }
    }

    private var groupedCards: [String: [Card]] {
        guard let cards = cardSet.cards as? Set<Card> else { return [:] }
        let sortedCards = cards.sorted { ($0.id, $0.front ?? "") < ($1.id, $1.front ?? "") }
        return Dictionary(grouping: sortedCards) { $0.groupName ?? "Ungrouped" }
    }

    private var sortedGroupNames: [String] {
        groupedCards.keys.sorted { groupName1, groupName2 in
            let groupId1 = groupedCards[groupName1]?.first?.groupId ?? Int32.max
            let groupId2 = groupedCards[groupName2]?.first?.groupId ?? Int32.max
            return groupId1 < groupId2
        }
    }
}

private struct CardRow: View {
    let card: Card

    @Environment(\.theme) var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.metrics.deckDetailCardRowSpacing) {
            Text(card.front ?? "No front")
                .font(.headline)
                .foregroundColor(theme.colors.textPrimary)
            Text(formattedBack)
                .font(.subheadline)
                .foregroundColor(theme.colors.textSecondary)
                .lineLimit(2)
        }
        .padding(theme.metrics.deckDetailCardRowPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: theme.metrics.cornerRadius)
                .fill(theme.gradients.card.opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: theme.metrics.cornerRadius)
                .stroke(theme.colors.surfaceLight, lineWidth: 1)
        )
        .shadow(color: theme.colors.shadow.opacity(0.4), radius: theme.metrics.deckDetailCardShadowRadius, x: 0, y: theme.metrics.deckDetailCardShadowY)
    }

    private var formattedBack: String {
        (card.back ?? "No back").replacingOccurrences(of: "\n", with: " ").replacingOccurrences(of: "<br>", with: " • ")
    }
}

private struct CardPreviewContainer: View {
    let card: Card
    let index: Int
    let total: Int
    let onClose: () -> Void

    @EnvironmentObject private var ttsService: TTSService
    @Environment(\.theme) var theme

    @State private var isFlipped = false

    var body: some View {
        SharedModalContainer(onClose: onClose) {
            SharedCardDisplayView(
                frontText: card.front ?? "No front",
                backText: formatBackText(),
                groupName: card.groupName ?? "",
                cardName: card.cardName ?? "",
                isFlipped: isFlipped,
                currentIndex: index,
                totalCards: total,
                cardId: Int(card.id),
                showSwipeFeedback: false,
                swipeDirection: nil,
                theme: theme
            )
            .padding(.horizontal, theme.metrics.deckDetailPreviewHorizontalPadding)
            .onTapGesture {
                UIImpactFeedbackGenerator.lightImpact()
                withAnimation(.bouncy) {
                    isFlipped.toggle()
                    speakCurrentText()
                }
            }
            .onAppear {
                speakCurrentText()
            }
            .onChange(of: index) { _ in
                // Reset to front side when card changes
                isFlipped = false
                // Stop any ongoing speech from previous card
                ttsService.stop()
                speakCurrentText()
            }
        }
        .onDisappear {
            ttsService.stop()
        }
    }

    private func formatBackText() -> String {
        guard let backText = card.back else { return "No back" }
        // Replace <br> with newlines for proper display
        return backText.replacingOccurrences(of: "<br>", with: "\n")
    }

    private func speakCurrentText() {
        let textToSpeak = isFlipped ? formatBackText() : (card.front ?? "")
        ttsService.speak(textToSpeak)
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let cardSet = CardSet(context: context)
    cardSet.name = "Sample Deck"
    cardSet.createdDate = Date()

    return NavigationView {
        DeckDetailView(cardSet: cardSet)
            .environment(\.managedObjectContext, context)
            .environmentObject(TTSService())
    }
}