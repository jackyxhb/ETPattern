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
    @State private var showingAutoView = false
    @State private var showingRenameAlert = false
    @State private var showingDeleteAlert = false
    @State private var showingExportAlert = false
    @State private var newName = ""
    @State private var browseCardSet: CardSet?

    var body: some View {
        NavigationView {
            List {
                ForEach(cardSets) { cardSet in
                    Button {
                        toggleSelection(for: cardSet)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(cardSet.name ?? "Unnamed Deck")
                                    .font(.headline)
                                if isSelected(cardSet) {
                                    Spacer()
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            Text("Created: \(cardSet.createdDate ?? Date(), formatter: dateFormatter)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            if let cards = cardSet.cards as? Set<Card> {
                                Text("\(cards.count) cards")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isSelected(cardSet) ? Color.accentColor.opacity(0.12) : Color(.secondarySystemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected(cardSet) ? Color.accentColor : Color.clear, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets())
                    .contextMenu {
                        Button {
                            promptRename(for: cardSet)
                        } label: {
                            Label("Rename", systemImage: "pencil")
                        }
                        Button {
                            selectedCardSet = cardSet
                            showingExportAlert = true
                        } label: {
                            Label("Export", systemImage: "square.and.arrow.up")
                        }
                        Button(role: .destructive) {
                            promptDelete(for: cardSet)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                .onDelete(perform: deleteCardSets)
            }
            .listStyle(.plain)
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
                ToolbarItem(placement: .navigationBarLeading) {
                    if selectedCardSet != nil {
                        Button("Clear Selection") {
                            clearSelection()
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
        .safeAreaInset(edge: .bottom) {
            if let selectedCardSet {
                CardSetActionBar(
                    onStudy: { startStudy(for: selectedCardSet) },
                    onAuto: { startAuto(for: selectedCardSet) },
                    onBrowse: { browseCardSet = selectedCardSet }
                )
            } else {
                EmptyView()
            }
        }
        .sheet(isPresented: $showingStudyView) {
            if let cardSet = selectedCardSet {
                StudyView(cardSet: cardSet)
            }
        }
        .sheet(isPresented: $showingAutoView) {
            if let cardSet = selectedCardSet {
                AutoPlayView(cardSet: cardSet)
            }
        }
        .sheet(item: $browseCardSet) { deck in
            NavigationView {
                DeckDetailView(cardSet: deck)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { browseCardSet = nil }
                        }
                    }
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
                    clearSelection()
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
            let toDelete = offsets.map { cardSets[$0] }
            toDelete.forEach(viewContext.delete)

            if let selected = selectedCardSet, toDelete.contains(selected) {
                clearSelection()
            }

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func toggleSelection(for cardSet: CardSet) {
        if selectedCardSet == cardSet {
            clearSelection()
        } else {
            selectedCardSet = cardSet
        }
    }

    private func isSelected(_ cardSet: CardSet) -> Bool {
        selectedCardSet == cardSet
    }

    private func clearSelection() {
        selectedCardSet = nil
    }

    private func startStudy(for cardSet: CardSet) {
        selectedCardSet = cardSet
        showingStudyView = true
    }

    private func startAuto(for cardSet: CardSet) {
        selectedCardSet = cardSet
        showingAutoView = true
    }

    private func promptRename(for cardSet: CardSet) {
        selectedCardSet = cardSet
        newName = cardSet.name ?? ""
        showingRenameAlert = true
    }

    private func promptDelete(for cardSet: CardSet) {
        selectedCardSet = cardSet
        showingDeleteAlert = true
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

private struct CardSetActionBar: View {
    let onStudy: () -> Void
    let onAuto: () -> Void
    let onBrowse: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Divider()
            HStack(spacing: 12) {
                ActionButton(title: "Study", systemImage: "play.fill", tint: .accentColor, action: onStudy)
                ActionButton(title: "Auto", systemImage: "play.circle", tint: .purple, action: onAuto)
                ActionButton(title: "Browse", systemImage: "list.bullet", tint: .blue, action: onBrowse)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(.ultraThinMaterial)
    }

    private struct ActionButton: View {
        let title: String
        let systemImage: String
        let tint: Color
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                Label(title, systemImage: systemImage)
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(tint.opacity(0.15))
                    .foregroundColor(tint)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(TTSService())
}
