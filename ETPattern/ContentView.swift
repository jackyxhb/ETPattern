//
//  ContentView.swift
//  ETPattern
//
//  Created by admin on 25/11/2025.
//

import SwiftUI
import CoreData
import UIKit

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CardSet.createdDate, ascending: false)],
        animation: .default)
    private var cardSets: FetchedResults<CardSet>

    @State private var selectedCardSet: CardSet?
    @State private var showingStudyView = false
    @State private var showingRenameAlert = false
    @State private var showingDeleteAlert = false
    @State private var showingExportAlert = false
    @State private var newName = ""

    var body: some View {
        NavigationView {
            List {
                ForEach(cardSets) { cardSet in
                    NavigationLink {
                        DeckDetailView(cardSet: cardSet)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(cardSet.name ?? "Unnamed Deck")
                                .font(.headline)
                            Text("Created: \(cardSet.createdDate ?? Date(), formatter: dateFormatter)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            if let cards = cardSet.cards as? Set<Card> {
                                Text("\(cards.count) cards")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .contextMenu {
                        Button {
                            // Quick study action
                            selectedCardSet = cardSet
                            showingStudyView = true
                        } label: {
                            Label("Quick Study", systemImage: "play.fill")
                        }

                        Button {
                            selectedCardSet = cardSet
                            showingRenameAlert = true
                            newName = cardSet.name ?? ""
                        } label: {
                            Label("Rename", systemImage: "pencil")
                        }

                        Button {
                            selectedCardSet = cardSet
                            showingExportAlert = true
                        } label: {
                            Label("Export", systemImage: "square.and.arrow.up")
                        }

                        Divider()

                        Button(role: .destructive) {
                            selectedCardSet = cardSet
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                .onDelete(perform: deleteCardSets)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        NavigationLink(destination: SessionStatsView()) {
                            Image(systemName: "chart.bar")
                                .imageScale(.large)
                        }
                        NavigationLink(destination: ImportView()) {
                            Image(systemName: "square.and.arrow.down")
                                .imageScale(.large)
                        }
                        NavigationLink(destination: SettingsView()) {
                            Image(systemName: "gear")
                                .imageScale(.large)
                        }
                    }
                }
                ToolbarItem {
                    Button(action: addCardSet) {
                        Label("Add Deck", systemImage: "plus")
                    }
                }
            }
            Text("Select a deck")
        }
        .sheet(isPresented: $showingStudyView) {
            if let cardSet = selectedCardSet {
                StudyView(cardSet: cardSet)
            }
        }
        .alert("Rename Deck", isPresented: $showingRenameAlert) {
            TextField("Deck Name", text: $newName)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                if let cardSet = selectedCardSet {
                    cardSet.name = newName
                    try? viewContext.save()
                }
            }
        }
        .alert("Delete Deck", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let cardSet = selectedCardSet {
                    viewContext.delete(cardSet)
                    try? viewContext.save()
                }
            }
        } message: {
            Text("Are you sure you want to delete this deck? This action cannot be undone.")
        }
        .alert("Export Deck", isPresented: $showingExportAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Export") {
                if let cardSet = selectedCardSet {
                    exportDeck(cardSet)
                }
            }
        } message: {
            Text("Export this deck as a CSV file?")
        }
        .navigationTitle("Flashcard Decks")
    }

    private func addCardSet() {
        withAnimation {
            let newCardSet = CardSet(context: viewContext)
            newCardSet.name = "New Deck"
            newCardSet.createdDate = Date()

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteCardSets(offsets: IndexSet) {
        withAnimation {
            offsets.map { cardSets[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func exportDeck(_ cardSet: CardSet) {
        // Create CSV content
        var csvContent = "Front;;Back;;Tags\n"

        if let cards = cardSet.cards as? Set<Card> {
            for card in cards.sorted(by: { ($0.front ?? "") < ($1.front ?? "") }) {
                let front = card.front?.replacingOccurrences(of: "\"", with: "\"\"") ?? ""
                let back = card.back?.replacingOccurrences(of: "\"", with: "\"\"").replacingOccurrences(of: "\n", with: "<br>") ?? ""
                let tags = card.tags?.replacingOccurrences(of: "\"", with: "\"\"") ?? ""

                csvContent += "\"\(front)\";;\"\(back)\";;\"\(tags)\"\n"
            }
        }

        // Share the CSV file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(cardSet.name ?? "deck").csv")
        do {
            try csvContent.write(to: tempURL, atomically: true, encoding: .utf8)

            // Present share sheet
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)

            // Find the current window scene
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                rootVC.present(activityVC, animated: true)
            }
        } catch {
            print("Error exporting deck: \(error)")
        }
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter
}()

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
