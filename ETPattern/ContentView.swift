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
            ZStack {
                DesignSystem.Gradients.background
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    heroHeader

                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(cardSets) { cardSet in
                                deckCard(for: cardSet)
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
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            deleteCardSet(cardSet)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding(.bottom, 120)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
            }
            .navigationTitle("Flashcard Decks")
            .navigationBarTitleDisplayMode(.inline)
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

    private func deleteCardSet(_ cardSet: CardSet) {
        withAnimation {
            viewContext.delete(cardSet)
            if selectedCardSet == cardSet {
                clearSelection()
            }
            do {
                try viewContext.save()
            } catch {
                print("Failed to delete deck: \(error.localizedDescription)")
            }
        }
    }

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("English Thought")
                .font(.largeTitle.bold())
                .foregroundColor(.white)
            Text("Tap a deck to jump back in")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
    }

    private func deckCard(for cardSet: CardSet) -> some View {
        let cardCount = (cardSet.cards as? Set<Card>)?.count ?? 0
        let createdText = dateFormatter.string(from: cardSet.createdDate ?? Date())

        return Button {
            toggleSelection(for: cardSet)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(cardSet.name ?? "Unnamed Deck")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Created \(createdText)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                    if isSelected(cardSet) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(DesignSystem.Colors.highlight)
                            .imageScale(.large)
                    }
                }

                HStack {
                    metricPill(title: "Cards", value: "\(cardCount)", icon: "rectangle.stack.fill")
                    Spacer()
                    metricPill(title: "Voice", value: UserDefaults.standard.string(forKey: "selectedVoice") ?? Constants.TTS.defaultVoice, icon: "waveform")
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 18)
            .background(
                DesignSystem.Gradients.card
                    .opacity(isSelected(cardSet) ? 1 : 0.85)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Metrics.cornerRadius)
                    .stroke(isSelected(cardSet) ? DesignSystem.Colors.highlight.opacity(0.8) : Color.white.opacity(0.15), lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: DesignSystem.Metrics.shadow.opacity(0.3), radius: 14, x: 0, y: 10)
        }
        .buttonStyle(.plain)
    }

    private func metricPill(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .imageScale(.small)
            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.white.opacity(0.55))
                Text(value)
                    .font(.callout.bold())
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
            Capsule()
                .fill(Color.white.opacity(0.3))
                .frame(width: 34, height: 3)
                .padding(.top, 6)

            HStack(spacing: 12) {
                ActionButton(title: "Study", systemImage: "bolt.fill", gradient: DesignSystem.Gradients.accent, action: onStudy)
                ActionButton(title: "Auto", systemImage: "waveform", gradient: DesignSystem.Gradients.success, action: onAuto)
                ActionButton(title: "Browse", systemImage: "list.bullet", gradient: DesignSystem.Gradients.card, action: onBrowse)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.horizontal, 16)
    }

    private struct ActionButton: View {
        let title: String
        let systemImage: String
        let gradient: LinearGradient
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                Label(title, systemImage: systemImage)
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(gradient)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
