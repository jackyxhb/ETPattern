//
//  ContentViewModel.swift
//  ETPattern
//
//  Created by admin on 25/11/2025.
//

import SwiftUI
import CoreData
import UIKit
import UniformTypeIdentifiers
import Combine

@MainActor
class ContentViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var uiState = UIState()

    // MARK: - Private Properties
    private let viewContext: NSManagedObjectContext
    private let csvImporter: CSVImporter

    // MARK: - Initialization
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
        self.csvImporter = CSVImporter(viewContext: viewContext)
    }

    func addCardSet() {
        withAnimation {
            let newCardSet = CardSet(context: viewContext)
            newCardSet.name = "New Deck"
            newCardSet.createdDate = Date()

            do {
                try viewContext.save()
            } catch {
                showError(title: "Failed to Create Deck", message: error.localizedDescription)
                viewContext.rollback()
            }
        }
    }

    func deleteCardSet(_ cardSet: CardSet) {
        withAnimation {
            viewContext.delete(cardSet)
            if uiState.selectedCardSet == cardSet {
                uiState.clearSelection()
            }
            do {
                try viewContext.save()
            } catch {
                showError(title: "Failed to Delete Deck", message: error.localizedDescription)
                viewContext.rollback()
            }
        }
    }

    func toggleSelection(for cardSet: CardSet) {
        if uiState.selectedCardSet == cardSet {
            uiState.clearSelection()
        } else {
            uiState.selectedCardSet = cardSet
        }
    }

    func isSelected(_ cardSet: CardSet) -> Bool {
        uiState.selectedCardSet == cardSet
    }

    func startStudy(for cardSet: CardSet) {
        uiState.selectedCardSet = cardSet
        uiState.showingStudyView = true
    }

    func startAuto(for cardSet: CardSet) {
        uiState.selectedCardSet = cardSet
        uiState.showingAutoView = true
    }

    func promptRename(for cardSet: CardSet) {
        uiState.selectedCardSet = cardSet
        uiState.newName = cardSet.name ?? ""
        uiState.showingRenameAlert = true
    }

    func promptDelete(for cardSet: CardSet) {
        uiState.selectedCardSet = cardSet
        uiState.showingDeleteAlert = true
    }

    func promptReimport(for cardSet: CardSet) {
        uiState.selectedCardSet = cardSet
        uiState.showingReimportAlert = true
    }

    func performRename() {
        guard let cardSet = uiState.selectedCardSet else { return }
        cardSet.name = uiState.newName
        do {
            try viewContext.save()
        } catch {
            showError(title: "Failed to Rename Deck", message: error.localizedDescription)
        }
    }

    func performDelete() {
        guard let cardSet = uiState.selectedCardSet else { return }
        deleteCardSet(cardSet)
    }

    func performReimport() {
        guard let cardSet = uiState.selectedCardSet else { return }
        if let kind = bundledDeckKind(for: cardSet) {
            reimportBundledDeck(cardSet, kind: kind)
        } else {
            uiState.showingReimportFilePicker = true
        }
    }

    func handleReimportFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first, let cardSet = uiState.selectedCardSet else { return }
            reimportCustomDeck(cardSet, from: url)
        case .failure(let error):
            showError(title: "Re-import Failed", message: error.localizedDescription)
        }
    }

    func exportDeck(_ cardSet: CardSet) {
        var csvContent = "Front;;Back;;Tags\n"

        if let cards = cardSet.cards as? Set<Card> {
            for card in cards.sorted(by: { ($0.front ?? "") < ($1.front ?? "") }) {
                let front = card.front?.replacingOccurrences(of: "\"", with: "\"\"") ?? ""
                let back = card.back?.replacingOccurrences(of: "\"", with: "\"\"").replacingOccurrences(of: "\n", with: "<br>") ?? ""
                let tags = card.tags?.replacingOccurrences(of: "\"", with: "\"\"") ?? ""

                csvContent += "\"\(front)\";;\"\(back)\";;\"\(tags)\"\n"
            }
        }

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(cardSet.name ?? "deck").csv")
        do {
            try csvContent.write(to: tempURL, atomically: true, encoding: .utf8)

            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)

            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                rootVC.present(activityVC, animated: true)
            }
        } catch {
            showError(title: "Export Failed", message: error.localizedDescription)
        }
    }

    func showBrowse(for cardSet: CardSet) {
        uiState.browseCardSet = cardSet
    }

    // MARK: - Private Methods

    private func showError(title: String, message: String) {
        uiState.errorTitle = title
        uiState.errorMessage = message
        uiState.showErrorAlert = true
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

    private func deleteAllCards(in cardSet: CardSet) {
        if let cards = cardSet.cards as? Set<Card> {
            for card in cards {
                viewContext.delete(card)
            }
        }
    }

    private func reimportBundledDeck(_ cardSet: CardSet, kind: BundledDeckKind) {
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
                let cards = csvImporter.parseCSV(content, cardSetName: Constants.Decks.bundledMasterName)
                for card in cards {
                    card.cardSet = cardSet
                    cardSet.addToCards(card)
                }
                importedCount += cards.count
            }
        case .group(let fileName):
            guard let content = FileManagerService.loadBundledCSV(named: fileName) else {
                showError(title: "Re-import Failed", message: "Failed to load bundled CSV \(fileName).")
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
            showError(title: "Re-import Failed", message: error.localizedDescription)
            viewContext.rollback()
            return
        }

        if !failures.isEmpty {
            showError(title: "Re-import Partially Failed",
                     message: "Imported \(importedCount) cards, but failed to load: \(failures.joined(separator: ", ")).")
        }
    }

    private func reimportCustomDeck(_ cardSet: CardSet, from url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            showError(title: "Re-import Failed", message: "Cannot access the selected file.")
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let cards = csvImporter.parseCSV(content, cardSetName: cardSet.name ?? "")

            guard !cards.isEmpty else {
                showError(title: "Re-import Failed", message: "No valid cards found in the CSV file. Please check the format.")
                return
            }

            deleteAllCards(in: cardSet)
            for card in cards {
                card.cardSet = cardSet
                cardSet.addToCards(card)
            }

            try viewContext.save()
        } catch {
            showError(title: "Re-import Failed", message: error.localizedDescription)
            viewContext.rollback()
        }
    }
}

// MARK: - UI State Struct
struct UIState {
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
    var showingOnboarding = false

    mutating func clearSelection() {
        selectedCardSet = nil
    }
}