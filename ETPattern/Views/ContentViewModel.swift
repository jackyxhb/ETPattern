//
//  ContentViewModel.swift
//  ETPattern
//
//  Created by admin on 25/11/2025.
//

import SwiftUI
import Combine

@MainActor
class ContentViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var uiState = UIState()

    // MARK: - Private Properties
    private let cardSetRepository: CardSetRepositoryProtocol
    private let csvService: CSVServiceProtocol
    private let shareService: ShareServiceProtocol

    // MARK: - Initialization
    init(
        cardSetRepository: CardSetRepositoryProtocol,
        csvService: CSVServiceProtocol,
        shareService: ShareServiceProtocol
    ) {
        self.cardSetRepository = cardSetRepository
        self.csvService = csvService
        self.shareService = shareService
    }

    func addCardSet() {
        Task {
            do {
                let _ = try await cardSetRepository.createCardSet(name: NSLocalizedString("new_deck", comment: "Default name for new decks"))
            } catch {
                showError(title: NSLocalizedString("create_deck_failed", comment: "Error title for failed deck creation"),
                         message: error.localizedDescription)
            }
        }
    }

    func deleteCardSet(_ cardSet: CardSet) {
        Task {
            do {
                try await cardSetRepository.deleteCardSet(cardSet)
                if uiState.selectedCardSet == cardSet {
                    uiState.clearSelection()
                }
            } catch {
                showError(title: NSLocalizedString("delete_deck_failed", comment: "Error title for failed deck deletion"),
                         message: error.localizedDescription)
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
        Task {
            do {
                try await cardSetRepository.updateCardSetName(cardSet, newName: uiState.newName)
            } catch {
                showError(title: NSLocalizedString("rename_deck_failed", comment: "Error title for failed deck rename"),
                         message: error.localizedDescription)
            }
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
            showError(title: NSLocalizedString("reimport_failed", comment: "Error title for failed reimport"),
                     message: error.localizedDescription)
        }
    }

    func exportDeck(_ cardSet: CardSet) {
        do {
            let csvContent = try csvService.exportCardSet(cardSet)
            try shareService.shareCSVContent(csvContent, fileName: cardSet.name ?? "deck")
        } catch {
            showError(title: NSLocalizedString("export_error", comment: "Error title for export failures"),
                     message: error.localizedDescription)
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

    private func bundledDeckKind(for cardSet: CardSet) -> CSVService.BundledDeckKind? {
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



    private func reimportBundledDeck(_ cardSet: CardSet, kind: CSVService.BundledDeckKind) {
        Task {
            do {
                let (importedCount, failures) = try await csvService.reimportBundledDeck(cardSet, kind: kind)

                if !failures.isEmpty {
                    showError(title: NSLocalizedString("reimport_partially_failed", comment: "Title for partial reimport failure"),
                             message: String(format: NSLocalizedString("reimport_partial_message", comment: "Message for partial reimport failure"), importedCount, failures.joined(separator: ", ")))
                }
            } catch {
                showError(title: NSLocalizedString("reimport_failed", comment: "Error title for failed reimport"),
                         message: error.localizedDescription)
            }
        }
    }

    private func reimportCustomDeck(_ cardSet: CardSet, from url: URL) {
        Task {
            do {
                let importedCount = try await csvService.reimportCustomDeck(cardSet, from: url)
            } catch {
                showError(title: NSLocalizedString("reimport_failed", comment: "Error title for failed reimport"),
                         message: error.localizedDescription)
            }
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