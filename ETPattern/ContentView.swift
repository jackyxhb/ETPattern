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
    @State private var hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    @State private var showingOnboarding = false

    var body: some View {
        NavigationView {
            ZStack {
                DesignSystem.Gradients.background
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    heroHeader

                    ScrollView {
                        if cardSets.isEmpty {
                            emptyStateView
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
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
                }
                .padding(.horizontal)
                .padding(.top, 20)
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
        .fullScreenCover(isPresented: $showingAutoView) {
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
        .fullScreenCover(isPresented: $showingOnboarding) {
            OnboardingView {
                UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                hasSeenOnboarding = true
                showingOnboarding = false
            }
        }
        .onAppear {
            if !hasSeenOnboarding {
                showingOnboarding = true
            }
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

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(DesignSystem.Gradients.accent.opacity(0.2))
                    .frame(width: 120, height: 120)

                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
            }

            VStack(spacing: 12) {
                Text("No Decks Yet")
                    .font(.title2.bold())
                    .foregroundColor(.white)

                Text("Create your first flashcard deck or import CSV files to get started with learning English patterns.")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }

            VStack(spacing: 16) {
                Button(action: {
                    UIImpactFeedbackGenerator.mediumImpact()
                    addCardSet()
                }) {
                    Label("Create New Deck", systemImage: "plus")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(DesignSystem.Gradients.accent)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                Button(action: {
                    UIImpactFeedbackGenerator.lightImpact()
                    // Navigate to import view
                }) {
                    Label("Import CSV", systemImage: "square.and.arrow.down")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.ultraThinMaterial)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(.vertical, 60)
    }

    private var heroHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("English Thought")
                .font(.largeTitle.bold())
                .foregroundColor(.white)
            Spacer()
            headerActions
        }
    }

    private var headerActions: some View {
        HStack(spacing: 10) {
            NavigationLink(destination: SessionStatsView()) {
                headerIcon(systemName: "chart.bar")
            }
            NavigationLink(destination: ImportView()) {
                headerIcon(systemName: "square.and.arrow.down")
            }
            NavigationLink(destination: SettingsView()) {
                headerIcon(systemName: "gear")
            }
        }
    }

    private func headerIcon(systemName: String) -> some View {
        Image(systemName: systemName)
            .imageScale(.medium)
            .foregroundColor(.white)
            .padding(10)
            .background(Color.white.opacity(0.15))
            .clipShape(Circle())
    }

    private func deckCard(for cardSet: CardSet) -> some View {
        let cardCount = (cardSet.cards as? Set<Card>)?.count ?? 0
        let createdText = dateFormatter.string(from: cardSet.createdDate ?? Date())

        return Button {
            UIImpactFeedbackGenerator.lightImpact()
            toggleSelection(for: cardSet)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("(\(cardCount))\(cardSet.name ?? "Unnamed Deck")")
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
            Button(action: {
                UIImpactFeedbackGenerator.mediumImpact()
                action()
            }) {
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
