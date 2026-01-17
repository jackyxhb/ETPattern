import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#endif
import ETPatternModels
import ETPatternServices

struct DeckDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) var theme

    let cardSet: CardSet

    @State private var previewCard: Card?

    @State private var groups: [String: [Card]] = [:]
    @State private var groupNames: [String] = []

    var body: some View {
        ZStack {
            // Background provided by sheet presentation (.ultraThinMaterial)
            
            VStack(spacing: 0) {
                // Custom header for sheet presentation
                HStack {
                    Text(cardSet.name)
                        .font(.headline)
                        .foregroundColor(theme.colors.textPrimary)
                        .dynamicTypeSize(.large ... .accessibility5)
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                        .foregroundColor(theme.colors.textSecondary)
                        .font(.title2)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)

                if groupNames.isEmpty {
                    Text("No cards in this deck")
                        .font(.headline)
                        .foregroundColor(theme.colors.textSecondary)
                        .dynamicTypeSize(.large ... .accessibility5)
                        .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: theme.metrics.deckDetailGroupSpacing) {
                            ForEach(groupNames, id: \.self) { groupName in
                                DisclosureGroup {
                                    LazyVStack(spacing: theme.metrics.deckDetailCardSpacing) {
                                        ForEach(groups[groupName] ?? []) { card in
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
                                            .dynamicTypeSize(.large ... .accessibility5)
                                        Spacer()
                                        Text("\(groups[groupName]?.count ?? 0) cards")
                                            .font(.subheadline)
                                            .foregroundColor(theme.colors.textSecondary)
                                            .dynamicTypeSize(.large ... .accessibility5)
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
        }
        .task {
            loadCards()
        }
        .fullScreenCover(item: $previewCard) { card in
            let allCards = groupNames.flatMap { groups[$0] ?? [] }
            let index = allCards.firstIndex(where: { $0.id == card.id }) ?? 0
            CardPreviewContainer(card: card, index: index, total: allCards.count) {
                previewCard = nil
            }
            .presentationBackground(.ultraThinMaterial)
        }
    }

    private func loadCards() {
        let cards = cardSet.cards
        let sortedCards = cards.sorted { ($0.id, $0.front) < ($1.id, $1.front) }
        let newGroups = Dictionary(grouping: sortedCards) { $0.groupName }
        
        self.groups = newGroups
        self.groupNames = newGroups.keys.sorted { groupName1, groupName2 in
            let groupId1 = newGroups[groupName1]?.first?.groupId ?? Int32.max
            let groupId2 = newGroups[groupName2]?.first?.groupId ?? Int32.max
            return groupId1 < groupId2
        }
    }
}

private struct CardRow: View {
    let card: Card

    @Environment(\.theme) var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.metrics.deckDetailCardRowSpacing) {
            Text(card.front)
                .font(.headline)
                .foregroundColor(theme.colors.textPrimary)
                .dynamicTypeSize(.large ... .accessibility5)
            Text(formattedBack)
                .font(.subheadline)
                .foregroundColor(theme.colors.textSecondary)
                .lineLimit(2)
                .dynamicTypeSize(.large ... .accessibility5)
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
        card.back.replacingOccurrences(of: "\n", with: " ").replacingOccurrences(of: "<br>", with: " • ")
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
                frontText: card.front,
                backText: formatBackText(),
                groupName: card.groupName,
                cardName: card.cardName,
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
                #if canImport(UIKit)
                UIImpactFeedbackGenerator.lightImpact()
                #endif
                withAnimation(.bouncy) {
                    isFlipped.toggle()
                    speakCurrentText()
                }
            }
            .onAppear {
                speakCurrentText()
            }
            .onChange(of: index) { _, _ in
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
        let backText = card.back
        // Replace <br> with newlines for proper display
        return backText.replacingOccurrences(of: "<br>", with: "\n")
    }

    private func speakCurrentText() {
        let textToSpeak = isFlipped ? formatBackText() : card.front
        ttsService.speak(textToSpeak)
    }
}

#Preview {
    NavigationView {
        DeckDetailView(cardSet: previewCardSet)
            .modelContainer(PersistenceController.preview.container)
            .environmentObject(TTSService.shared)
    }
}

@MainActor
private var previewCardSet: CardSet {
    let container = PersistenceController.preview.container
    let cardSet = CardSet(name: "Sample Deck")
    container.mainContext.insert(cardSet)
    return cardSet
}