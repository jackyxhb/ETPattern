//
//  ContentView.swift
//  ETPattern
//
//  Created by admin on 25/11/2025.
//

import SwiftUI
import CoreData
import UIKit
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.theme) var theme

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
    @State private var showingReimportAlert = false
    @State private var showingReimportFilePicker = false
    @State private var newName = ""
    @State private var browseCardSet: CardSet?
    @State private var hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    @State private var showingOnboarding = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var errorTitle = ""
    @State private var showingSessionStats = false
    @State private var showingImport = false
    @State private var showingSettings = false

    var body: some View {
        NavigationView {
            ZStack {
                theme.gradients.background
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
                                                promptReimport(for: cardSet)
                                            } label: {
                                                Label("Re-import", systemImage: "arrow.clockwise")
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
        .fullScreenCover(isPresented: $showingStudyView) {
            if let cardSet = selectedCardSet {
                StudyView(cardSet: cardSet)
            }
        }
        .fullScreenCover(isPresented: $showingAutoView) {
            if let cardSet = selectedCardSet {
                AutoPlayView(cardSet: cardSet)
            }
        }
        .sheet(isPresented: $showingSessionStats) {
            NavigationView {
                SessionStatsView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { showingSessionStats = false }
                        }
                    }
            }
        }
        .sheet(isPresented: $showingImport) {
            NavigationView {
                ImportView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { showingImport = false }
                        }
                    }
            }
        }
        .sheet(isPresented: $showingSettings) {
            NavigationView {
                SettingsView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { showingSettings = false }
                        }
                    }
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
        .alert("Re-import Deck", isPresented: $showingReimportAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Re-import", role: .destructive) {
                guard let cardSet = selectedCardSet else { return }
                performReimport(for: cardSet)
            }
        } message: {
            Text("This will replace all cards in the deck with the source CSV.")
        }
        .fileImporter(
            isPresented: $showingReimportFilePicker,
            allowedContentTypes: [UTType.commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            handleReimportFileSelection(result)
        }
        .alert(errorTitle, isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
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
                errorTitle = "Failed to Create Deck"
                errorMessage = error.localizedDescription
                showErrorAlert = true
                // Rollback the unsaved changes
                viewContext.rollback()
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

    private func promptReimport(for cardSet: CardSet) {
        selectedCardSet = cardSet
        showingReimportAlert = true
    }

    private enum BundledDeckKind {
        case master
        case group(fileName: String)
    }

    private func bundledDeckKind(for cardSet: CardSet) -> BundledDeckKind? {
        let name = (cardSet.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if name == Constants.Decks.bundledMasterName || name == Constants.Decks.legacyBundledMasterName {
            return .master
        }
        if name.hasPrefix("Group "),
           let number = Int(name.replacingOccurrences(of: "Group ", with: "")),
           (1...12).contains(number) {
            return .group(fileName: "Group\(number)")
        }
        return nil
    }

    private func performReimport(for cardSet: CardSet) {
        // Bundled decks can be re-imported without a file picker.
        if let kind = bundledDeckKind(for: cardSet) {
            reimportBundledDeck(cardSet, kind: kind)
            return
        }

        // Custom decks require selecting a CSV file.
        showingReimportFilePicker = true
    }

    private func handleReimportFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first, let cardSet = selectedCardSet else { return }
            reimportCustomDeck(cardSet, from: url)
        case .failure(let error):
            errorTitle = "Re-import Failed"
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }

    private func deleteAllCards(in cardSet: CardSet) {
        if let cards = cardSet.cards as? Set<Card> {
            for card in cards {
                viewContext.delete(card)
            }
        }
    }

    private func reimportBundledDeck(_ cardSet: CardSet, kind: BundledDeckKind) {
        let csvImporter = CSVImporter(viewContext: viewContext)
        let bundledFiles = FileManagerService.getBundledCSVFiles()

        deleteAllCards(in: cardSet)

        var importedCount = 0
        var failures: [String] = []

        switch kind {
        case .master:
            // Always keep master name standardized.
            cardSet.name = Constants.Decks.bundledMasterName
            for fileName in bundledFiles {
                guard let content = FileManagerService.loadBundledCSV(named: fileName) else {
                    failures.append(fileName)
                    continue
                }
                let cards = csvImporter.parseCSV(content, cardSetName: Constants.Decks.bundledMasterName)
                for card in cards {
                    card.cardSet = cardSet
                    cardSet.addToCards(card)
                }
                importedCount += cards.count
            }
        case .group(let fileName):
            guard let content = FileManagerService.loadBundledCSV(named: fileName) else {
                errorTitle = "Re-import Failed"
                errorMessage = "Failed to load bundled CSV \(fileName)."
                showErrorAlert = true
                viewContext.rollback()
                return
            }
            let cards = csvImporter.parseCSV(content, cardSetName: cardSet.name ?? "")
            for card in cards {
                card.cardSet = cardSet
                cardSet.addToCards(card)
            }
            importedCount = cards.count
        }

        do {
            try viewContext.save()
        } catch {
            errorTitle = "Re-import Failed"
            errorMessage = error.localizedDescription
            showErrorAlert = true
            viewContext.rollback()
            return
        }

        if !failures.isEmpty {
            errorTitle = "Re-import Partially Failed"
            errorMessage = "Imported \(importedCount) cards, but failed to load: \(failures.joined(separator: ", "))."
            showErrorAlert = true
        }
    }

    private func reimportCustomDeck(_ cardSet: CardSet, from url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            errorTitle = "Re-import Failed"
            errorMessage = "Cannot access the selected file."
            showErrorAlert = true
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let csvImporter = CSVImporter(viewContext: viewContext)
            let cards = csvImporter.parseCSV(content, cardSetName: cardSet.name ?? "")

            guard !cards.isEmpty else {
                errorTitle = "Re-import Failed"
                errorMessage = "No valid cards found in the CSV file. Please check the format."
                showErrorAlert = true
                return
            }

            deleteAllCards(in: cardSet)
            for card in cards {
                card.cardSet = cardSet
                cardSet.addToCards(card)
            }

            try viewContext.save()
        } catch {
            errorTitle = "Re-import Failed"
            errorMessage = error.localizedDescription
            showErrorAlert = true
            viewContext.rollback()
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

    private func deleteCardSet(_ cardSet: CardSet) {
        withAnimation {
            viewContext.delete(cardSet)
            if selectedCardSet == cardSet {
                clearSelection()
            }
            do {
                try viewContext.save()
            } catch {
                errorTitle = "Failed to Delete Deck"
                errorMessage = error.localizedDescription
                showErrorAlert = true
                // Rollback the deletion
                viewContext.rollback()
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(theme.gradients.accent.opacity(0.2))
                    .frame(width: 120, height: 120)

                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(theme.colors.textPrimary)
            }

            VStack(spacing: 12) {
                Text("No Decks Yet")
                    .font(.title2.bold())
                    .foregroundColor(theme.colors.textPrimary)

                Text("Create your first flashcard deck or import CSV files to get started with learning English patterns.")
                    .font(.body)
                    .foregroundColor(theme.colors.textSecondary)
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
                        .background(theme.gradients.accent)
                        .foregroundColor(theme.colors.textPrimary)
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
                        .foregroundColor(theme.colors.textPrimary)
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
                .foregroundColor(theme.colors.textPrimary)
            Spacer()
            headerActions
        }
    }

    private var headerActions: some View {
        HStack(spacing: 10) {
            Button {
                UIImpactFeedbackGenerator.lightImpact()
                showingSessionStats = true
            } label: {
                headerIcon(systemName: "chart.bar")
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("chart.bar")
            .accessibilityLabel("chart.bar")

            Button {
                UIImpactFeedbackGenerator.lightImpact()
                showingImport = true
            } label: {
                headerIcon(systemName: "square.and.arrow.down")
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("square.and.arrow.down")
            .accessibilityLabel("square.and.arrow.down")

            Button {
                UIImpactFeedbackGenerator.lightImpact()
                showingSettings = true
            } label: {
                headerIcon(systemName: "gear")
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("gear")
            .accessibilityLabel("gear")
        }
    }

    private func headerIcon(systemName: String) -> some View {
        Image(systemName: systemName)
            .imageScale(.medium)
            .foregroundColor(theme.colors.textPrimary)
            .padding(10)
            .background(theme.colors.surfaceLight)
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
                            .foregroundColor(theme.colors.textPrimary)
                        Text("Created \(createdText)")
                            .font(.caption)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    Spacer()
                    if isSelected(cardSet) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(theme.colors.highlight)
                            .imageScale(.large)
                    }
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 18)
            .background(
                theme.gradients.card
                    .opacity(isSelected(cardSet) ? 1 : 0.85)
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.metrics.cornerRadius)
                    .stroke(isSelected(cardSet) ? theme.colors.highlight.opacity(0.8) : theme.colors.surfaceLight, lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: theme.colors.shadow.opacity(0.3), radius: 14, x: 0, y: 10)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("deckCard")
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter
}()

private struct CardSetActionBar: View {
    @Environment(\.theme) var theme
    let onStudy: () -> Void
    let onAuto: () -> Void
    let onBrowse: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Capsule()
                .fill(theme.colors.textPrimary.opacity(0.3))
                .frame(width: 34, height: 3)
                .padding(.top, 6)

            HStack(spacing: 12) {
                ActionButton(title: "Study", systemImage: "bolt.fill", gradient: theme.gradients.accent, action: onStudy)
                ActionButton(title: "Auto", systemImage: "waveform", gradient: theme.gradients.success, action: onAuto)
                ActionButton(title: "Browse", systemImage: "list.bullet", gradient: theme.gradients.card, action: onBrowse)
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
