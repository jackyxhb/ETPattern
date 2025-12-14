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

            if sortedGroupNames.isEmpty {
                VStack {
                    Spacer()
                    Text("No cards in this deck")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Progress Section
                        VStack(spacing: 16) {
                            HStack {
                                Text("Mastery")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(Int(masteryPercentage))%")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                            ProgressView(value: masteryPercentage / 100)
                                .progressViewStyle(LinearProgressViewStyle(tint: .green))
                                .scaleEffect(y: 2)
                            
                            DisclosureGroup("Review History") {
                                LazyVStack(spacing: 8) {
                                    ForEach(sortedStudySessions) { session in
                                        HStack {
                                            Text(session.date ?? Date(), style: .date)
                                                .foregroundColor(.white.opacity(0.8))
                                            Spacer()
                                            Text("\(session.correctCount)/\(session.cardsReviewed) correct")
                                                .foregroundColor(.white.opacity(0.6))
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                                .padding(.top, 8)
                            }
                            .tint(.white)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.Metrics.cornerRadius)
                                .fill(DesignSystem.Gradients.card.opacity(0.9))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.Metrics.cornerRadius)
                                .stroke(DesignSystem.Colors.stroke, lineWidth: 1)
                        )
                        
                        // Cards Section
                        ForEach(sortedGroupNames, id: \.self) { groupName in
                            DisclosureGroup {
                                LazyVStack(spacing: 12) {
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
                                .padding(.leading, 16)
                            } label: {
                                HStack {
                                    Text(groupName)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text("\(groupedCards[groupName]?.count ?? 0) cards")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: DesignSystem.Metrics.cornerRadius)
                                        .fill(DesignSystem.Gradients.card.opacity(0.9))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignSystem.Metrics.cornerRadius)
                                        .stroke(DesignSystem.Colors.stroke, lineWidth: 1)
                                )
                            }
                            .tint(.white)
                        }
                    }
                    .padding()
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

    private var masteryPercentage: Double {
        guard let cards = cardSet.cards as? Set<Card>, !cards.isEmpty else { return 0 }
        let totalReviewed = cards.reduce(0) { $0 + Int($1.timesReviewed) }
        let totalCorrect = cards.reduce(0) { $0 + Int($1.timesCorrect) }
        return totalReviewed > 0 ? Double(totalCorrect) / Double(totalReviewed) * 100 : 0
    }

    private var sortedStudySessions: [StudySession] {
        guard let sessions = cardSet.studySessions as? Set<StudySession> else { return [] }
        return sessions.sorted { ($0.date ?? Date()) > ($1.date ?? Date()) }
    }

    private var groupedCards: [String: [Card]] {
        guard let cards = cardSet.cards as? Set<Card> else { return [:] }
        let sortedCards = cards.sorted { ($0.front ?? "") < ($1.front ?? "") }
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