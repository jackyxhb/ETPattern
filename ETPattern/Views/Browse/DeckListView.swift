import SwiftUI
import SwiftData
import ETPatternModels
import ETPatternCore
import ETPatternServices
import ETPatternServices

public struct DeckListView: View {
    @State private var viewModel: DeckListViewModel
    @Binding var selectedSet: CardSet?
    @Environment(\.theme) var theme
    
    // Grid Columns for Bento Style
    private let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 16)
    ]
    
    public init(selectedSet: Binding<CardSet?>, service: CardServiceProtocol) {
        self._selectedSet = selectedSet
        self._viewModel = State(initialValue: DeckListViewModel(service: service))
    }

    public var body: some View {
        ScrollView {
            if viewModel.isLoading && viewModel.cardSets.isEmpty {
                ProgressView()
                    .padding()
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else if viewModel.cardSets.isEmpty {
                emptyStateView
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    // Add New Deck Tile at the start
                    addDeckTile
                    
                    ForEach(viewModel.cardSets) { cardSet in
                        deckCard(for: cardSet)
                            .contextMenu { contextMenu(for: cardSet) }
                    }
                }
                .padding()
            }
        }
        .scrollContentBackground(.hidden)
        .task {
            await viewModel.onAppear()
        }
        .refreshable {
            await viewModel.loadCardSets()
        }
        .alert("New Deck", isPresented: $viewModel.showingCreateAlert) {
            TextField("Deck Name", text: $viewModel.newDeckName)
            Button("Cancel", role: .cancel) { }
            Button("Create") {
                viewModel.createDeck()
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "square.stack.3d.up.slash")
                .font(.system(size: 60))
                .foregroundStyle(theme.colors.textSecondary.opacity(0.3))
            
            Text("No Decks Yet")
                .font(.title3.bold())
                .foregroundStyle(theme.colors.textPrimary)
            
            Text("Create your first flashcard deck to get started.")
                .font(.subheadline)
                .foregroundStyle(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                viewModel.showingCreateAlert = true
            } label: {
                Label("Create New Deck", systemImage: "plus")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(theme.gradients.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(.horizontal, 40)
        }
        .padding(.vertical, 60)
    }

    @ViewBuilder
    private func contextMenu(for cardSet: CardSet) -> some View {
        Button(role: .destructive) {
            withAnimation {
                if selectedSet?.id == cardSet.id {
                    selectedSet = nil
                }
                viewModel.deleteSet(cardSet)
            }
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
    
    private var addDeckTile: some View {
        Button {
            viewModel.showingCreateAlert = true
        } label: {
            VStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(theme.colors.textSecondary.opacity(0.5))
                Text("New Deck")
                    .font(.headline)
                    .foregroundStyle(theme.colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120) // Approximate height matching Bento cards
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                    .foregroundStyle(theme.colors.textSecondary.opacity(0.3))
            )
        }
        .buttonStyle(.plain)
    }

    private func deckCard(for cardSet: CardSet) -> some View {
        let cardCount = cardSet.cards.count
        let isSelected = selectedSet?.id == cardSet.id
        
        return Button {
            #if canImport(UIKit)
            UIImpactFeedbackGenerator.lightImpact()
            #endif
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if isSelected {
                    selectedSet = nil
                } else {
                    selectedSet = cardSet
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "rectangle.stack.fill")
                        .font(.title2)
                        .foregroundStyle(theme.gradients.accent)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(theme.colors.highlight)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(cardSet.name)
                        .font(.headline)
                        .lineLimit(2)
                        .foregroundStyle(theme.colors.textPrimary)
                        .multilineTextAlignment(.leading)
                    
                    Text("\(cardCount) cards")
                        .font(.caption)
                        .foregroundStyle(theme.colors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? theme.colors.highlight.opacity(0.8) : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }
}