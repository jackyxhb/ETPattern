//
//  ContentView.swift
//  ETPattern
//
//  Created by admin on 25/11/2025.
//

import CoreData
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.theme) var theme

    // MARK: - Data Fetching
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CardSet.createdDate, ascending: false)],
        animation: .default)
    private var cardSets: FetchedResults<CardSet>

    // MARK: - UI State
    @State private var uiState = UIState()

    // MARK: - Onboarding State
    @State private var hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    @State private var showingOnboarding = false

    var body: some View {
        NavigationView {
            ZStack {
                theme.gradients.background
                    .ignoresSafeArea()

                mainContent
            }
            .navigationTitle("Flashcard Decks")
            .navigationBarHidden(true) // Custom header
        }
        .safeAreaInset(edge: .bottom) {
            if let selectedCardSet = uiState.selectedCardSet {
                CardSetActionBar(
                    onStudy: { startStudy(for: selectedCardSet) },
                    onAuto: { startAuto(for: selectedCardSet) },
                    onBrowse: { uiState.browseCardSet = selectedCardSet }
                )
            } else {
                EmptyView()
            }
        }
        .fullScreenCover(isPresented: $uiState.showingStudyView) {
            if let cardSet = uiState.selectedCardSet {
                StudyView(cardSet: cardSet)
            }
        }
        .fullScreenCover(isPresented: $uiState.showingAutoView) {
            if let cardSet = uiState.selectedCardSet {
                AutoPlayView(cardSet: cardSet)
            }
        }
        .sheet(isPresented: $uiState.showingSessionStats) {
            NavigationView {
                SessionStatsView()
                    .navigationTitle("Session Stats")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { uiState.showingSessionStats = false }
                        }
                    }
                    .toolbarBackground(.ultraThinMaterial.opacity(0.8), for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
                    .toolbarColorScheme(.dark, for: .navigationBar)
                }
        }
        .sheet(isPresented: $uiState.showingImport) {
            NavigationView {
                ImportView()
                    .navigationTitle("Import")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { uiState.showingImport = false }
                        }
                    }
                    .toolbarBackground(.ultraThinMaterial.opacity(0.8), for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
                    .toolbarColorScheme(.dark, for: .navigationBar)
                }
        }
        .sheet(isPresented: $uiState.showingSettings) {
            NavigationView {
                SettingsView()
                    .navigationTitle("Settings")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { uiState.showingSettings = false }
                        }
                    }
                    .toolbarBackground(.ultraThinMaterial.opacity(0.8), for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
                    .toolbarColorScheme(.dark, for: .navigationBar)
                }
        }
        .sheet(item: $uiState.browseCardSet) { deck in
            NavigationView {
                DeckDetailView(cardSet: deck)
                    .navigationTitle(deck.name ?? "Deck Details")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { uiState.browseCardSet = nil }
                        }
                    }
                    .toolbarBackground(.ultraThinMaterial.opacity(0.8), for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
                    .toolbarColorScheme(.dark, for: .navigationBar)
                }
        }
        .alert("Rename Deck", isPresented: $uiState.showingRenameAlert) {
            TextField("Deck Name", text: $uiState.newName)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                if let cardSet = uiState.selectedCardSet {
                    cardSet.name = uiState.newName
                    try? viewContext.save()
                }
            }
        }
        .alert("Delete Deck", isPresented: $uiState.showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let cardSet = uiState.selectedCardSet {
                    viewContext.delete(cardSet)
                    uiState.clearSelection()
                    try? viewContext.save()
                }
            }
        } message: {
            Text("Are you sure you want to delete this deck? This action cannot be undone.")
        }
        .alert("Export Deck", isPresented: $uiState.showingExportAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Export") {
                if let cardSet = uiState.selectedCardSet {
                    exportDeck(cardSet)
                }
            }
        } message: {
            Text("Export this deck as a CSV file?")
        }
        .alert("Re-import Deck", isPresented: $uiState.showingReimportAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Re-import", role: .destructive) {
                guard let cardSet = uiState.selectedCardSet else { return }
                performReimport(for: cardSet)
            }
        } message: {
            Text("This will replace all cards in the deck with the source CSV.")
        }
        .fileImporter(
            isPresented: $uiState.showingReimportFilePicker,
            allowedContentTypes: [UTType.commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            handleReimportFileSelection(result)
        }
        .alert(uiState.errorTitle, isPresented: $uiState.showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(uiState.errorMessage)
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
    }

    // MARK: - Main Content
    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            heroHeader

            ScrollView {
                if cardSets.isEmpty {
                    emptyStateView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    deckList
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 20)
    }

    // MARK: - Deck List
    private var deckList: some View {
        LazyVStack(spacing: 14) {
            ForEach(cardSets) { cardSet in
                deckCard(for: cardSet)
                    .contextMenu { contextMenu(for: cardSet) }
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

    // MARK: - Context Menu
    @ViewBuilder
    private func contextMenu(for cardSet: CardSet) -> some View {
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
            uiState.selectedCardSet = cardSet
            uiState.showingExportAlert = true
        } label: {
            Label("Export", systemImage: "square.and.arrow.up")
        }
        Button(role: .destructive) {
            promptDelete(for: cardSet)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    // MARK: - Bottom Action Bar
    private var actionBar: some View {
        Group {
            if let selectedCardSet = uiState.selectedCardSet {
                CardSetActionBar(
                    onStudy: { startStudy(for: selectedCardSet) },
                    onAuto: { startAuto(for: selectedCardSet) },
                    onBrowse: { uiState.browseCardSet = selectedCardSet }
                )
            } else {
                EmptyView()
            }
        }
    }

    // MARK: - Subviews
    private var heroHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("English Thought")
                .font(theme.typography.title.bold())
                .foregroundColor(theme.colors.textPrimary)
            Spacer()
            headerActions
        }
    }

    private var headerActions: some View {
        Button(action: {
            UIImpactFeedbackGenerator.lightImpact()
            uiState.showingHeaderMenu = true
        }) {
            headerIcon(systemName: "ellipsis")
        }
        .popover(isPresented: $uiState.showingHeaderMenu) {
            ZStack {
                theme.colors.surfaceElevated
                    .clipShape(RoundedRectangle(cornerRadius: theme.metrics.cornerRadius))
                    .shadow(color: theme.colors.shadow.opacity(0.3), radius: 10)
                VStack(spacing: 0) {
                    Button {
                        uiState.showingSessionStats = true
                        uiState.showingHeaderMenu = false
                    } label: {
                        Label("Session Stats", systemImage: "chart.bar")
                            .foregroundColor(theme.colors.onSurfaceElevated)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                    .buttonStyle(.plain)

                    Button {
                        uiState.showingImport = true
                        uiState.showingHeaderMenu = false
                    } label: {
                        Label("Import", systemImage: "square.and.arrow.down")
                            .foregroundColor(theme.colors.onSurfaceElevated)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                    .buttonStyle(.plain)

                    Button {
                        uiState.showingSettings = true
                        uiState.showingHeaderMenu = false
                    } label: {
                        Label("Settings", systemImage: "gear")
                            .foregroundColor(theme.colors.onSurfaceElevated)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                    .buttonStyle(.plain)

                    Button {
                        showingOnboarding = true
                        uiState.showingHeaderMenu = false
                    } label: {
                        Label("Onboarding", systemImage: "questionmark.circle")
                            .foregroundColor(theme.colors.onSurfaceElevated)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
            .presentationDetents([.height(240)])
        }
    }

    private func headerButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator.lightImpact()
            action()
        } label: {
            headerIcon(systemName: systemName)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(systemName)
        .accessibilityLabel(systemName)
    }

    private func headerIcon(systemName: String) -> some View {
        Image(systemName: systemName)
            .imageScale(.medium)
            .foregroundColor(theme.colors.textPrimary)
            .padding(10)
            .background(theme.colors.surfaceLight)
            .clipShape(Circle())
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

                Text(
                    "Create your first flashcard deck or import CSV files to get started with learning English patterns."
                )
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
                    uiState.showingImport = true
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
                    .stroke(
                        isSelected(cardSet)
                            ? theme.colors.highlight.opacity(0.8) : theme.colors.surfaceLight,
                        lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: theme.colors.shadow.opacity(0.3), radius: 14, x: 0, y: 10)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("deckCard")
    }

    // MARK: - Helper Methods
    private func toggleSelection(for cardSet: CardSet) {
        if uiState.selectedCardSet == cardSet {
            uiState.clearSelection()
        } else {
            uiState.selectedCardSet = cardSet
        }
    }

    private func isSelected(_ cardSet: CardSet) -> Bool {
        uiState.selectedCardSet == cardSet
    }

    private func startStudy(for cardSet: CardSet) {
        uiState.selectedCardSet = cardSet
        uiState.showingStudyView = true
    }

    private func startAuto(for cardSet: CardSet) {
        uiState.selectedCardSet = cardSet
        uiState.showingAutoView = true
    }

    private func promptRename(for cardSet: CardSet) {
        uiState.selectedCardSet = cardSet
        uiState.newName = cardSet.name ?? ""
        uiState.showingRenameAlert = true
    }

    private func promptDelete(for cardSet: CardSet) {
        uiState.selectedCardSet = cardSet
        uiState.showingDeleteAlert = true
    }

    private func promptReimport(for cardSet: CardSet) {
        uiState.selectedCardSet = cardSet
        uiState.showingReimportAlert = true
    }

    // MARK: - Business Logic Methods
    private func addCardSet() {
        withAnimation {
            let newCardSet = CardSet(context: viewContext)
            newCardSet.name = "New Deck"
            newCardSet.createdDate = Date()

            do {
                try viewContext.save()
            } catch {
                uiState.errorTitle = "Failed to Create Deck"
                uiState.errorMessage = error.localizedDescription
                uiState.showErrorAlert = true
                viewContext.rollback()
            }
        }
    }

    private func deleteCardSet(_ cardSet: CardSet) {
        withAnimation {
            viewContext.delete(cardSet)
            if uiState.selectedCardSet == cardSet {
                uiState.clearSelection()
            }
            do {
                try viewContext.save()
            } catch {
                uiState.errorTitle = "Failed to Delete Deck"
                uiState.errorMessage = error.localizedDescription
                uiState.showErrorAlert = true
                viewContext.rollback()
            }
        }
    }

    private func performReimport(for cardSet: CardSet) {
        if let kind = bundledDeckKind(for: cardSet) {
            reimportBundledDeck(cardSet, kind: kind)
        } else {
            uiState.showingReimportFilePicker = true
        }
    }

    private func handleReimportFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first, let cardSet = uiState.selectedCardSet else { return }
            reimportCustomDeck(cardSet, from: url)
        case .failure(let error):
            uiState.errorTitle = "Re-import Failed"
            uiState.errorMessage = error.localizedDescription
            uiState.showErrorAlert = true
        }
    }

    private func exportDeck(_ cardSet: CardSet) {
        var csvContent = "Front;;Back;;Tags\n"

        if let cards = cardSet.cards as? Set<Card> {
            for card in cards.sorted(by: { ($0.front ?? "") < ($1.front ?? "") }) {
                let front = card.front?.replacingOccurrences(of: "\"", with: "\"\"") ?? ""
                let back =
                    card.back?.replacingOccurrences(of: "\"", with: "\"\"").replacingOccurrences(
                        of: "\n", with: "<br>") ?? ""
                let tags = card.tags?.replacingOccurrences(of: "\"", with: "\"\"") ?? ""

                csvContent += "\"\(front)\";;\"\(back)\";;\"\(tags)\"\n"
            }
        }

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(
            "\(cardSet.name ?? "deck").csv")
        do {
            try csvContent.write(to: tempURL, atomically: true, encoding: .utf8)

            let activityVC = UIActivityViewController(
                activityItems: [tempURL], applicationActivities: nil)

            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                let window = windowScene.windows.first,
                let rootVC = window.rootViewController
            {
                rootVC.present(activityVC, animated: true)
            }
        } catch {
            print("Error exporting deck: \(error)")
        }
    }

    private enum BundledDeckKind {
        case master
        case group(fileName: String)
    }

    private func bundledDeckKind(for cardSet: CardSet) -> BundledDeckKind? {
        let name = (cardSet.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if name == Constants.Decks.bundledMasterName
            || name == Constants.Decks.legacyBundledMasterName
        {
            return .master
        }
        if name.hasPrefix("Group "),
            let number = Int(name.replacingOccurrences(of: "Group ", with: "")),
            (1...12).contains(number)
        {
            return .group(fileName: "Group\(number)")
        }
        return nil
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
            cardSet.name = Constants.Decks.bundledMasterName
            for fileName in bundledFiles {
                guard let content = FileManagerService.loadBundledCSV(named: fileName) else {
                    failures.append(fileName)
                    continue
                }
                let cards = csvImporter.parseCSV(
                    content, cardSetName: Constants.Decks.bundledMasterName)
                for card in cards {
                    card.cardSet = cardSet
                    cardSet.addToCards(card)
                }
                importedCount += cards.count
            }
        case .group(let fileName):
            guard let content = FileManagerService.loadBundledCSV(named: fileName) else {
                uiState.errorTitle = "Re-import Failed"
                uiState.errorMessage = "Failed to load bundled CSV \(fileName)."
                uiState.showErrorAlert = true
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
            uiState.errorTitle = "Re-import Failed"
            uiState.errorMessage = error.localizedDescription
            uiState.showErrorAlert = true
            viewContext.rollback()
            return
        }

        if !failures.isEmpty {
            uiState.errorTitle = "Re-import Partially Failed"
            uiState.errorMessage =
                "Imported \(importedCount) cards, but failed to load: \(failures.joined(separator: ", "))."
            uiState.showErrorAlert = true
        }
    }

    private func reimportCustomDeck(_ cardSet: CardSet, from url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            uiState.errorTitle = "Re-import Failed"
            uiState.errorMessage = "Cannot access the selected file."
            uiState.showErrorAlert = true
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let csvImporter = CSVImporter(viewContext: viewContext)
            let cards = csvImporter.parseCSV(content, cardSetName: cardSet.name ?? "")

            guard !cards.isEmpty else {
                uiState.errorTitle = "Re-import Failed"
                uiState.errorMessage = "No valid cards found in the CSV file. Please check the format."
                uiState.showErrorAlert = true
                return
            }

            deleteAllCards(in: cardSet)
            for card in cards {
                card.cardSet = cardSet
                cardSet.addToCards(card)
            }

            try viewContext.save()
        } catch {
            uiState.errorTitle = "Re-import Failed"
            uiState.errorMessage = error.localizedDescription
            uiState.showErrorAlert = true
            viewContext.rollback()
        }
    }
}

// MARK: - UI State Struct
private struct UIState {
    var selectedCardSet: CardSet?
    var showingStudyView = false
    var showingAutoView = false
    var showingRenameAlert = false
    var showingDeleteAlert = false
    var showingExportAlert = false
    var showingReimportAlert = false
    var showingReimportFilePicker = false
    var newName = ""
    var browseCardSet: CardSet?
    var showErrorAlert = false
    var errorMessage = ""
    var errorTitle = ""
    var showingSessionStats = false
    var showingImport = false
    var showingSettings = false
    var showingHeaderMenu = false

    mutating func clearSelection() {
        selectedCardSet = nil
    }
}

// MARK: - CardSetActionBar
private struct CardSetActionBar: View {
    let onStudy: () -> Void
    let onAuto: () -> Void
    let onBrowse: () -> Void

    @Environment(\.theme) private var theme: Theme

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                ActionButton(
                    title: "Study", systemImage: "book", gradient: theme.gradients.accent,
                    action: onStudy)
                ActionButton(
                    title: "Auto", systemImage: "waveform", gradient: theme.gradients.success,
                    action: onAuto)
                ActionButton(
                    title: "Browse", systemImage: "list.bullet", gradient: theme.gradients.neutral,
                    action: onBrowse)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 6)
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

        @Environment(\.theme) private var theme: Theme

        var body: some View {
            Button(action: {
                UIImpactFeedbackGenerator.mediumImpact()
                action()
            }) {
                Label(title, systemImage: systemImage)
                    .font(theme.typography.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(gradient)
                    .foregroundColor(theme.colors.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Date Formatter
private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter
}()

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(TTSService())
}
