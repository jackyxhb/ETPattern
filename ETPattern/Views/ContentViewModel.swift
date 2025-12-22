//
//  ContentViewModel.swift
//  ETPattern
//
//  Created by admin on 25/11/2025.
//

import SwiftUI
@preconcurrency import Combine

@MainActor
class ContentViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var uiState = UIState()

    // MARK: - Private Properties
    private let cardSetRepository: CardSetRepositoryProtocol
    private let csvService: CSVServiceProtocol
    private let shareService: ShareServiceProtocol
    private let paginatedDataSource: PaginatedCardSetDataSourceProtocol
    
    // MARK: - Cancellable Storage
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init(
        cardSetRepository: CardSetRepositoryProtocol,
        csvService: CSVServiceProtocol,
        shareService: ShareServiceProtocol,
        paginatedDataSource: PaginatedCardSetDataSourceProtocol
    ) {
        self.cardSetRepository = cardSetRepository
        self.csvService = csvService
        self.shareService = shareService
        self.paginatedDataSource = paginatedDataSource
        
        setupSubscriptions()
    }
    
    // MARK: - Paginated Data Access
    var cardSets: [CardSet] {
        paginatedDataSource.cardSets
    }
    
    var isLoadingCardSets: Bool {
        paginatedDataSource.isLoading
    }
    
    var hasMoreCardSets: Bool {
        paginatedDataSource.hasMoreData
    }
    
    var cardSetsError: AppError? {
        paginatedDataSource.error
    }
    
    func loadInitialCardSets() async {
        await paginatedDataSource.loadInitialData()
    }
    
    func loadMoreCardSets() async {
        await paginatedDataSource.loadMoreData()
    }
    
    func refreshCardSets() async {
        await paginatedDataSource.refreshData()
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
    
    // MARK: - Private Setup Methods
    private func setupSubscriptions() {
        // Subscribe to paginated data source changes to trigger view updates
        if let observableDataSource = paginatedDataSource as? PaginatedCardSetDataSource {
            subscribeWeak(to: observableDataSource.$cardSets, storeIn: &cancellables) { viewModel, _ in
                // Trigger objectWillChange when cardSets change
                viewModel.objectWillChange.send()
            }
            
            subscribeWeak(to: observableDataSource.$isLoading, storeIn: &cancellables) { viewModel, _ in
                viewModel.objectWillChange.send()
            }
            
            subscribeWeak(to: observableDataSource.$hasMoreData, storeIn: &cancellables) { viewModel, _ in
                viewModel.objectWillChange.send()
            }
            
            subscribeWeak(to: observableDataSource.$error, storeIn: &cancellables) { viewModel, _ in
                viewModel.objectWillChange.send()
            }
        }
        
        // Example of proper Combine subscription with memory management:
        // subscribeWeak(to: somePublisher, storeIn: &cancellables) { strongSelf, value in
        //     // Handle value with guaranteed strong self reference
        //     strongSelf.handleValue(value)
        // }
        
        // Or for publishers that don't need weak self:
        // subscribe(to: somePublisher, storeIn: &cancellables) { value in
        //     // Handle value (self is guaranteed to exist)
        // }
        
        // Currently no subscriptions, but infrastructure is ready
    }

    func addCardSet() {
        uiState.isCreatingDeck = true
        Task {
            do {
                let _ = try await cardSetRepository.createCardSet(name: NSLocalizedString("new_deck", comment: "Default name for new decks"))
                // Refresh data after adding
                await refreshCardSets()
            } catch {
                showError(title: NSLocalizedString("create_deck_failed", comment: "Error title for failed deck creation"),
                         message: error.localizedDescription)
            }
            uiState.isCreatingDeck = false
        }
    }

    func deleteCardSet(_ cardSet: CardSet) {
        uiState.isDeletingDeck = true
        Task {
            do {
                try await cardSetRepository.deleteCardSet(cardSet)
                // Refresh data after deleting
                await refreshCardSets()
                if uiState.selectedCardSet == cardSet {
                    uiState.clearSelection()
                }
            } catch {
                showError(title: NSLocalizedString("delete_deck_failed", comment: "Error title for failed deck deletion"),
                         message: error.localizedDescription)
            }
            uiState.isDeletingDeck = false
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
                // Refresh data after renaming
                await refreshCardSets()
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
        uiState.isReimporting = true
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
            uiState.isReimporting = false
        }
    }

    private func reimportCustomDeck(_ cardSet: CardSet, from url: URL) {
        uiState.isReimporting = true
        Task {
            do {
                let importedCount = try await csvService.reimportCustomDeck(cardSet, from: url)
            } catch {
                showError(title: NSLocalizedString("reimport_failed", comment: "Error title for failed reimport"),
                         message: error.localizedDescription)
            }
            uiState.isReimporting = false
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
    var isReimporting = false
    var isCreatingDeck = false
    var isDeletingDeck = false

    mutating func clearSelection() {
        selectedCardSet = nil
    }
}