//
//  DeckListView.swift
//  ETPattern
//
//  Created by admin on 25/11/2025.
//

import SwiftUI
import SwiftData
import ETPatternModels
import ETPatternServices

struct DeckListView: View {
    @ObservedObject var viewModel: ContentViewModel
    let cardSets: [CardSet]
    @Environment(\.theme) var theme

    var body: some View {
        LazyVStack(spacing: theme.metrics.deckListSpacing) {
            ForEach(cardSets) { cardSet in
                deckCard(for: cardSet)
                    .contextMenu { contextMenu(for: cardSet) }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            viewModel.deleteCardSet(cardSet)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .disabled(viewModel.uiState.isReimporting || viewModel.uiState.isDeletingDeck)
                    }
            }
            
            // Load more indicator
            if viewModel.hasMoreCardSets && !viewModel.cardSets.isEmpty {
                loadMoreIndicator
                    .onAppear {
                        Task {
                            await viewModel.loadMoreCardSets()
                        }
                    }
            }
        }
        .padding(.bottom, theme.metrics.deckCardBottomPadding)
    }

    @ViewBuilder
    private func contextMenu(for cardSet: CardSet) -> some View {
        Button {
            viewModel.promptRename(for: cardSet)
        } label: {
            Label("Rename", systemImage: "pencil")
        }
        .disabled(viewModel.uiState.isReimporting || viewModel.uiState.isDeletingDeck)
        
        Button {
            viewModel.promptReimport(for: cardSet)
        } label: {
            Label("Re-import", systemImage: "arrow.clockwise")
        }
        .disabled(viewModel.uiState.isReimporting || viewModel.uiState.isDeletingDeck)
        
        Button {
            viewModel.uiState.selectedCardSet = cardSet
            viewModel.uiState.showingExportAlert = true
        } label: {
            Label("Export", systemImage: "square.and.arrow.up")
        }
        .disabled(viewModel.uiState.isReimporting || viewModel.uiState.isDeletingDeck)
        
        Button(role: .destructive) {
            viewModel.promptDelete(for: cardSet)
        } label: {
            Label("Delete", systemImage: "trash")
        }
        .disabled(viewModel.uiState.isReimporting || viewModel.uiState.isDeletingDeck)
    }

    private func deckCard(for cardSet: CardSet) -> some View {
        let cardCount = cardSet.cards.count
        let createdText = dateFormatter.string(from: cardSet.createdDate)

        return Button {
            UIImpactFeedbackGenerator.lightImpact()
            viewModel.toggleSelection(for: cardSet)
        } label: {
            VStack(alignment: .leading, spacing: theme.metrics.deckCardInnerSpacing) {
                HStack {
                    VStack(alignment: .leading, spacing: theme.metrics.deckCardTextSpacing) {
                        Text(String(format: NSLocalizedString("cards_count", comment: "Card count display format"), cardCount, cardSet.name))
                            .font(.headline)
                            .foregroundColor(theme.colors.textPrimary)
                        Text(String(format: NSLocalizedString("created_text", comment: "Created date display format"), createdText))
                            .font(.caption)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    Spacer()
                    if viewModel.isSelected(cardSet) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(theme.colors.highlight)
                            .imageScale(.large)
                    }
                }
            }
            .padding(.vertical, theme.metrics.deckCardVerticalPadding)
            .padding(.horizontal, theme.metrics.deckCardHorizontalPadding)
            .background(
                theme.gradients.card
                    .opacity(viewModel.isSelected(cardSet) ? 1 : 0.85)
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.metrics.cornerRadius)
                    .stroke(
                        viewModel.isSelected(cardSet)
                            ? theme.colors.highlight.opacity(0.8) : theme.colors.surfaceLight,
                        lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: theme.metrics.cornerRadius, style: .continuous))
            .shadow(color: theme.colors.shadow.opacity(0.3), radius: theme.metrics.shadowRadius, x: 0, y: theme.metrics.shadowY)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("deckCard")
    }
    
    private var loadMoreIndicator: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                ProgressView()
                    .tint(theme.colors.textPrimary)
                Text("Loading more decks...")
                    .font(.caption)
                    .foregroundColor(theme.colors.textPrimary.opacity(0.7))
            }
            Spacer()
        }
        .padding(.vertical, 16)
    }
}

// MARK: - Date Formatter
private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter
}()