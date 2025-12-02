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

    @State private var showingStudyView = false
    @State private var showingRenameAlert = false
    @State private var newName = ""

    var body: some View {
        VStack {
            if let cards = cardSet.cards as? Set<Card>, !cards.isEmpty {
                List(Array(cards).sorted(by: { ($0.front ?? "") < ($1.front ?? "") })) { card in
                    VStack(alignment: .leading) {
                        Text(card.front ?? "No front")
                            .font(.headline)
                        Text(card.back ?? "No back")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
            } else {
                Text("No cards in this deck")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle(cardSet.name ?? "Unnamed Deck")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingStudyView = true }) {
                        Label("Study", systemImage: "play.fill")
                    }
                    Button(action: {
                        newName = cardSet.name ?? ""
                        showingRenameAlert = true
                    }) {
                        Label("Rename", systemImage: "pencil")
                    }
                    Button(role: .destructive, action: deleteDeck) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingStudyView) {
            StudyView(cardSet: cardSet)
        }
        .alert("Rename Deck", isPresented: $showingRenameAlert) {
            TextField("Deck Name", text: $newName)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                cardSet.name = newName
                try? viewContext.save()
            }
        }
    }

    private func deleteDeck() {
        viewContext.delete(cardSet)
        try? viewContext.save()
        dismiss()
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