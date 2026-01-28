import SwiftUI
import SwiftData
import UIKit

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
                        .font(.title2.bold()) // Stronger title
                        .foregroundColor(theme.colors.textPrimary)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(theme.colors.textSecondary)
                            .font(.title2)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .overlay(Divider(), alignment: .bottom)

                if groupNames.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(theme.colors.textSecondary.opacity(0.5))
                        Text("No cards in this deck")
                            .font(.headline)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(groupNames, id: \.self) { groupName in
                                LiquidDisclosureGroup(
                                    title: groupName,
                                    count: groups[groupName]?.count ?? 0,
                                    theme: theme
                                ) {
                                    LazyVStack(spacing: 12) {
                                        ForEach(groups[groupName] ?? []) { card in
                                            Button {
                                                previewCard = card
                                            } label: {
                                                CardRow(card: card)
                                            }
                                            .buttonStyle(.plain)
                                            .contextMenu {
                                                Button { previewCard = card } label: {
                                                    Label("Preview", systemImage: "eye")
                                                }
                                            }
                                        }
                                    }
                                    .padding(.top, 8)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .transition(.asymmetric(insertion: .scale(scale: 0.95).combined(with: .opacity), removal: .opacity))
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
        let cards = cardSet.safeCards
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

// MARK: - Components

private struct LiquidDisclosureGroup<Content: View>: View {
    let title: String
    let count: Int
    let theme: Theme
    let content: Content
    
    @State private var isExpanded = true // Default to expanded for better visibility
    
    init(title: String, count: Int, theme: Theme, @ViewBuilder content: () -> Content) {
        self.title = title
        self.count = count
        self.theme = theme
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
                UIImpactFeedbackGenerator.snap() // Snap!
            }) {
                HStack {
                    Image(systemName: "folder.fill")
                        .foregroundColor(.blue)
                    Text(title)
                        .font(.headline)
                        .foregroundColor(theme.colors.textPrimary)
                    Spacer()
                    Text("\(count)")
                        .font(.callout.monospacedDigit())
                        .foregroundColor(theme.colors.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.primary.opacity(0.05))
                        .clipShape(Capsule())
                    
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundColor(theme.colors.textSecondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding()
                .background(.ultraThinMaterial)
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                content
                    .padding(.horizontal)
                    .padding(.bottom)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }
}

private struct CardRow: View {
    let card: Card
    @Environment(\.theme) var theme

    var body: some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(theme.gradients.accent)
                .frame(width: 4)
                .cornerRadius(2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(card.front)
                    .font(.body.weight(.medium))
                    .foregroundColor(theme.colors.textPrimary)
                    .lineLimit(1)
                
                Text(formattedBack)
                    .font(.subheadline)
                    .foregroundColor(theme.colors.textSecondary)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
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
                UIImpactFeedbackGenerator.lightImpact()
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