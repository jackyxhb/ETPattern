//
//  DeckDetailView.swift
//  ETPattern
//
//  Created by admin on 25/11/2025.
//

import SwiftUI
import CoreData

struct DeckDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let cardSet: CardSet

    @State private var previewCard: Card?

    var body: some View {
        ZStack {
            DesignSystem.Gradients.background
                .ignoresSafeArea()

            if sortedCards.isEmpty {
                Text("No cards in this deck")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.7))
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(sortedCards) { card in
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
                    .padding()
                }
            }
        }
        .navigationTitle(cardSet.name ?? "Unnamed Deck")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $previewCard) { card in
            let cards = sortedCards
            let index = cards.firstIndex(where: { $0.objectID == card.objectID }) ?? 0
            CardPreviewContainer(card: card, index: index, total: cards.count) {
                previewCard = nil
            }
        }
    }

    private var sortedCards: [Card] {
        guard let cards = cardSet.cards as? Set<Card> else { return [] }
        return cards.sorted { ($0.front ?? "") < ($1.front ?? "") }
    }
}

private struct CardRow: View {
    let card: Card

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(card.front ?? "No front")
                .font(.headline)
                .foregroundColor(.white)
            Text(formattedBack)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(2)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Metrics.cornerRadius)
                .fill(DesignSystem.Gradients.card.opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Metrics.cornerRadius)
                .stroke(DesignSystem.Colors.stroke, lineWidth: 1)
        )
        .shadow(color: DesignSystem.Metrics.shadow.opacity(0.4), radius: 12, x: 0, y: 8)
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

    var body: some View {
        ZStack(alignment: .topTrailing) {
            DesignSystem.Gradients.background
                .ignoresSafeArea()

            CardView(card: card, currentIndex: index, totalCards: total)
                .padding(.horizontal)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.2), in: Circle())
                    .padding()
            }
            .accessibilityLabel("Close preview")
        }
        .onDisappear {
            ttsService.stop()
        }
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