//
//  ContentView.swift
//  ETPattern
//
//  Created by admin on 25/11/2025.
//

import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.theme) var theme

    @StateObject private var viewModel: ContentViewModel

    // MARK: - Onboarding State
    @State private var hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")

    init() {
        let viewContext = PersistenceController.shared.container.viewContext
        let backgroundContextManager = BackgroundContextManager(persistentContainer: PersistenceController.shared.container)
        let cardSetRepository = CardSetRepository(viewContext: viewContext, backgroundContextManager: backgroundContextManager)
        let csvImporter = CSVImporter(viewContext: viewContext)
        let csvService = CSVService(viewContext: viewContext, csvImporter: csvImporter, backgroundContextManager: backgroundContextManager)
        let shareService = ShareService()
        let paginatedDataSource = PaginatedCardSetDataSource(viewContext: viewContext)
        
        _viewModel = StateObject(wrappedValue: ContentViewModel(
            cardSetRepository: cardSetRepository,
            csvService: csvService,
            shareService: shareService,
            paginatedDataSource: paginatedDataSource
        ))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.gradients.background
                    .ignoresSafeArea()

                mainContent
            }
            .navigationTitle(NSLocalizedString("flashcard_decks", comment: "Main screen title"))
            .navigationBarHidden(true) // Custom header
            .onAppear {
                Task {
                    await viewModel.loadInitialCardSets()
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if let selectedCardSet = viewModel.uiState.selectedCardSet {
                CardSetActionBar(
                    onStudy: { viewModel.startStudy(for: selectedCardSet) },
                    onAuto: { viewModel.startAuto(for: selectedCardSet) },
                    onBrowse: { viewModel.showBrowse(for: selectedCardSet) }
                )
            } else {
                EmptyView()
            }
        }
        .fullScreenCover(isPresented: $viewModel.uiState.showingStudyView) {
            if let cardSet = viewModel.uiState.selectedCardSet {
                StudyView(cardSet: cardSet)
            }
        }
        .fullScreenCover(isPresented: $viewModel.uiState.showingAutoView) {
            if let cardSet = viewModel.uiState.selectedCardSet {
                AutoPlayView(cardSet: cardSet)
            }
        }
        .sheet(isPresented: $viewModel.uiState.showingSessionStats) {
            SessionStatsView()
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $viewModel.uiState.showingImport) {
            ImportView()
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $viewModel.uiState.showingSettings) {
            SettingsView()
                .presentationDetents([.medium, .large])
        }
        .sheet(item: $viewModel.uiState.browseCardSet) { deck in
            DeckDetailView(cardSet: deck)
                .presentationDetents([.medium, .large])
        }
        .alert("Rename Deck", isPresented: $viewModel.uiState.showingRenameAlert) {
            TextField("Deck Name", text: $viewModel.uiState.newName)
            Button(NSLocalizedString("cancel", comment: "Cancel button"), role: .cancel) {}
            Button(NSLocalizedString("save", comment: "Save button")) {
                viewModel.performRename()
            }
        }
        .alert("Delete Deck", isPresented: $viewModel.uiState.showingDeleteAlert) {
            Button(NSLocalizedString("cancel", comment: "Cancel button"), role: .cancel) {}
            Button(NSLocalizedString("delete", comment: "Delete button"), role: .destructive) {
                viewModel.performDelete()
            }
        } message: {
            Text(NSLocalizedString("delete_deck_confirmation", comment: "Confirmation message for deleting a deck"))
        }
        .alert("Export Deck", isPresented: $viewModel.uiState.showingExportAlert) {
            Button(NSLocalizedString("cancel", comment: "Cancel button"), role: .cancel) {}
            Button(NSLocalizedString("export", comment: "Export button")) {
                if let cardSet = viewModel.uiState.selectedCardSet {
                    viewModel.exportDeck(cardSet)
                }
            }
        } message: {
            Text(NSLocalizedString("export_deck_message", comment: "Message asking if user wants to export deck"))
        }
        .alert("Re-import Deck", isPresented: $viewModel.uiState.showingReimportAlert) {
            Button(NSLocalizedString("cancel", comment: "Cancel button"), role: .cancel) {}
            Button(NSLocalizedString("re_import", comment: "Re-import button"), role: .destructive) {
                viewModel.performReimport()
            }
        } message: {
            Text(NSLocalizedString("reimport_warning", comment: "Warning about reimport replacing cards"))
        }
        .fileImporter(
            isPresented: $viewModel.uiState.showingReimportFilePicker,
            allowedContentTypes: [UTType.commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            viewModel.handleReimportFileSelection(result)
        }
        .alert(viewModel.uiState.errorTitle, isPresented: $viewModel.uiState.showErrorAlert) {
            Button(NSLocalizedString("ok", comment: "OK button"), role: .cancel) {}
        } message: {
            Text(viewModel.uiState.errorMessage)
        }
        .fullScreenCover(isPresented: $viewModel.uiState.showingOnboarding) {
            OnboardingView {
                UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                hasSeenOnboarding = true
                viewModel.uiState.showingOnboarding = false
            }
        }
        .onAppear {
            if !hasSeenOnboarding {
                viewModel.uiState.showingOnboarding = true
            }
        }
    }

    // MARK: - Main Content
    private var mainContent: some View {
        VStack(alignment: .leading, spacing: theme.metrics.mainContentSpacing) {
            HeaderView(viewModel: viewModel)

            ScrollView {
                if viewModel.isLoadingCardSets && viewModel.cardSets.isEmpty {
                    loadingStateView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.cardSets.isEmpty && !viewModel.isLoadingCardSets {
                    emptyStateView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    DeckListView(viewModel: viewModel, cardSets: viewModel.cardSets)
                }
            }
        }
        .padding(.horizontal, theme.metrics.contentHorizontalPadding)
        .padding(.top, theme.metrics.contentTopPadding)
    }

    private var loadingStateView: some View {
        VStack(spacing: theme.metrics.emptyStateVerticalSpacing) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(theme.colors.textPrimary)
            
            Text("Loading decks...")
                .font(.headline)
                .foregroundColor(theme.colors.textPrimary.opacity(0.8))
                .dynamicTypeSize(.large ... .accessibility5)
        }
    }

    private var emptyStateView: some View {
        SharedEmptyStateView(
            title: NSLocalizedString("no_decks_title", comment: "Title for empty decks state"),
            description: NSLocalizedString("no_decks_description", comment: "Description for empty decks state"),
            theme: theme,
            circleSize: theme.metrics.emptyStateCircleSize,
            circleOpacity: theme.metrics.emptyStateCircleOpacity,
            verticalSpacing: theme.metrics.emptyStateVerticalSpacing,
            textSpacing: theme.metrics.emptyStateTextSpacing,
            horizontalPadding: theme.metrics.emptyStateHorizontalPadding
        ) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: theme.metrics.emptyStateIconSize))
                .foregroundColor(theme.colors.textPrimary)
        } additionalContent: {
            VStack(spacing: theme.metrics.emptyStateButtonSpacing) {
                Button(action: {
                    UIImpactFeedbackGenerator.mediumImpact()
                    viewModel.addCardSet()
                }) {
                    Label("Create New Deck", systemImage: "plus")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, theme.metrics.emptyStateButtonVerticalPadding)
                        .background(theme.gradients.accent)
                        .foregroundColor(theme.colors.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: theme.metrics.emptyStateButtonCornerRadius, style: .continuous))
                        .dynamicTypeSize(.large ... .accessibility5)
                }

                Button(action: {
                    UIImpactFeedbackGenerator.lightImpact()
                    viewModel.uiState.showingImport = true
                }) {
                    Label("Import CSV", systemImage: "square.and.arrow.down")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, theme.metrics.emptyStateButtonVerticalPadding)
                        .background(.ultraThinMaterial)
                        .foregroundColor(theme.colors.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: theme.metrics.emptyStateButtonCornerRadius, style: .continuous))
                        .dynamicTypeSize(.large ... .accessibility5)
                }
            }
            .padding(.horizontal, theme.metrics.emptyStateButtonHorizontalPadding)
            .padding(.top, theme.metrics.emptyStateButtonTopPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(.vertical, theme.metrics.emptyStateVerticalPadding)
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
            HStack(spacing: theme.metrics.actionBarButtonSpacing) {
                ActionButton(
                    title: NSLocalizedString("study", comment: "Study action button"),
                    systemImage: "book", gradient: theme.gradients.accent,
                    action: onStudy)
                ActionButton(
                    title: NSLocalizedString("auto_play", comment: "Auto play action button"),
                    systemImage: "waveform", gradient: theme.gradients.success,
                    action: onAuto)
                ActionButton(
                    title: NSLocalizedString("browse", comment: "Browse action button"),
                    systemImage: "list.bullet", gradient: theme.gradients.neutral,
                    action: onBrowse)
            }
            .padding(.horizontal, theme.metrics.actionBarHorizontalPadding)
            .padding(.vertical, theme.metrics.actionBarVerticalPadding)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: theme.metrics.actionBarCornerRadius, style: .continuous))
        .padding(.horizontal, theme.metrics.actionBarContainerHorizontalPadding)
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
                    .font(theme.metrics.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, theme.metrics.actionButtonVerticalPadding)
                    .background(gradient)
                    .foregroundColor(theme.colors.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: theme.metrics.actionButtonCornerRadius, style: .continuous))
                    .dynamicTypeSize(.large ... .accessibility5)
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(TTSService.shared)
}
