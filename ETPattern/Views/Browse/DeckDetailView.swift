import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#endif
import ETPatternModels
import ETPatternServices
import ETPatternCore
import ETPatternServices

struct DeckDetailView: View {
    @Environment(\.theme) var theme
    
    @State var viewModel: DeckDetailViewModel
    @ObservedObject var coordinator: BrowseCoordinator

    var body: some View {
        ZStack {
            // Liquid Background
            LiquidBackground()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text(viewModel.deckName)
                        .font(.headline)
                        .foregroundColor(theme.colors.textPrimary)
                        .dynamicTypeSize(.large ... .accessibility5)
                    Spacer()
                    Button(action: {
                        viewModel.addCard()
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(theme.colors.highlight)
                            .font(.title2)
                    }
                    .padding(.trailing, 8)

                    Button(action: {
                        viewModel.close()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                        .foregroundColor(theme.colors.textSecondary)
                        .font(.title2)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)

                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxHeight: .infinity)
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(theme.colors.danger)
                        .padding()
                } else if viewModel.sections.isEmpty {
                    Text("No cards in this deck")
                        .font(.headline)
                        .foregroundColor(theme.colors.textSecondary)
                        .dynamicTypeSize(.large ... .accessibility5)
                        .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: theme.metrics.deckDetailGroupSpacing) {
                            ForEach(viewModel.sections) { section in
                                DisclosureGroup {
                                    LazyVStack(spacing: theme.metrics.deckDetailCardSpacing) {
                                        ForEach(section.cards) { card in
                                            Button {
                                                viewModel.previewCard(card)
                                            } label: {
                                                CardRow(card: card)
                                            }
                                            .buttonStyle(.plain)
                                            .contextMenu {
                                                Button {
                                                    viewModel.previewCard(card)
                                                } label: {
                                                    Label("Preview", systemImage: "eye")
                                                }
                                                Button {
                                                    viewModel.editCard(card)
                                                } label: {
                                                    Label("Edit", systemImage: "pencil")
                                                }
                                            }
                                        }
                                    }
                                    .padding(.leading, theme.metrics.deckDetailLeadingPadding)
                                } label: {
                                    HStack {
                                        Text(section.groupName)
                                            .font(.headline)
                                            .foregroundColor(theme.colors.textPrimary)
                                            .dynamicTypeSize(.large ... .accessibility5)
                                        Spacer()
                                        Text("\(section.cards.count) cards")
                                            .font(.subheadline)
                                            .foregroundColor(theme.colors.textSecondary)
                                            .dynamicTypeSize(.large ... .accessibility5)
                                    }
                                    .bentoTileStyle()
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
            await viewModel.loadData()
        }
        #if os(iOS)
        .fullScreenCover(item: $coordinator.previewCard) { card in
            // Calculate index and total for the preview
            // This logic ideally sits in VM, but for display purity:
            let allCards = viewModel.sections.flatMap { $0.cards }
            let index = allCards.firstIndex(where: { $0.id == card.id }) ?? 0
            
            CardPreviewContainer(card: card, index: index, total: allCards.count) {
                viewModel.dismissPreview()
            }
            #if os(iOS)
            .presentationBackground(.ultraThinMaterial)
            #endif
        }
        #else
        .sheet(item: $coordinator.previewCard) { card in
            let allCards = viewModel.sections.flatMap { $0.cards }
            let index = allCards.firstIndex(where: { $0.id == card.id }) ?? 0
            
            CardPreviewContainer(card: card, index: index, total: allCards.count) {
                viewModel.dismissPreview()
            }
        }
        #endif
        .sheet(item: $coordinator.editingCard) { cardModel in
            // For new cards, coordinator sets editingCard to a dummy or we handle nil in VM
            // In our case, we pass nil to vm if adding new
            let isNew = cardModel.id == 0 && cardModel.front == ""
            let vm = EditCardViewModel(
                card: isNew ? nil : cardModel,
                deckName: viewModel.deckName,
                service: viewModel.service,
                coordinator: coordinator
            )
            EditCardView(viewModel: vm)
                #if os(iOS)
                .presentationBackground(.ultraThinMaterial)
                #endif
        }
    }
}

private struct CardRow: View {
    let card: CardDisplayModel
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
        .bentoTileStyle()
        .shadow(color: theme.colors.shadow.opacity(0.4), radius: theme.metrics.deckDetailCardShadowRadius, x: 0, y: theme.metrics.deckDetailCardShadowY)
    }

    private var formattedBack: String {
        card.back.replacingOccurrences(of: "\n", with: " ").replacingOccurrences(of: "<br>", with: " • ")
    }
}

private struct CardPreviewContainer: View {
    let card: CardDisplayModel
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
                isFlipped = false
                ttsService.stop()
                speakCurrentText()
            }
        }
        .onDisappear {
            ttsService.stop()
        }
    }

    private func formatBackText() -> String {
        card.back.replacingOccurrences(of: "<br>", with: "\n")
    }

    private func speakCurrentText() {
        let textToSpeak = isFlipped ? formatBackText() : card.front
        ttsService.speak(textToSpeak)
    }
}