//
//  ContentView.swift
//  ETPattern
//
//  Created by admin on 25/11/2025.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import os.log
import ETPatternModels
import ETPatternServices
import ETPatternServices
import ETPatternCore

struct ContentView: View {
    @Environment(\.theme) var theme

    @StateObject private var viewModel: ContentViewModel
    
    private let modelContext: ModelContext
    private let cardService: CardService
    private let logger = Logger(subsystem: "com.jack.ETPattern", category: "ContentView")

    // MARK: - Onboarding State
    @State private var hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.cardService = CardService(modelContainer: modelContext.container)
        
        let cardSetRepository = CardSetRepository(modelContext: modelContext)
        let csvImporter = CSVImporter(modelContext: modelContext)
        let csvService = CSVService(modelContext: modelContext, csvImporter: csvImporter)
        let shareService = ShareService()
        let paginatedDataSource = PaginatedCardSetDataSource(modelContext: modelContext)
        
        _viewModel = StateObject(wrappedValue: ContentViewModel(
            cardSetRepository: cardSetRepository,
            csvService: csvService,
            shareService: shareService,
            paginatedDataSource: paginatedDataSource
        ))
    }

    var body: some View {
        let onboardingStatus = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
        logger.info("ContentView: body called, hasSeenOnboarding = \(onboardingStatus)")
        return NavigationStack {
            ZStack {
                theme.gradients.background
                    .ignoresSafeArea()

                mainContent
            }
            .navigationTitle(NSLocalizedString("flashcard_decks", comment: "Main screen title"))
            #if os(iOS)
            .navigationBarHidden(true) // Custom header
            #endif
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
        #if os(iOS)
        .fullScreenCover(isPresented: $viewModel.uiState.showingStudyView) {
            if let cardSet = viewModel.uiState.selectedCardSet {
                // Initialize MVVM+ Stack
                // Note: In a larger app, this composition might happen in a Factory or Router.
                let coordinator = StudyCoordinator(onDismiss: {
                    viewModel.uiState.showingStudyView = false
                })
                
                // Create Service with isolated context
                let container = modelContext.container
                let service = StudyService(modelContainer: container)
                
                let studyVM = StudyViewModel(
                    cardSet: cardSet,
                    modelContext: modelContext,
                    service: service,
                    coordinator: coordinator
                )
                
                StudyView(viewModel: studyVM)
            }
        }
        #else
        .sheet(isPresented: $viewModel.uiState.showingStudyView) {
             if let cardSet = viewModel.uiState.selectedCardSet {
                let coordinator = StudyCoordinator(onDismiss: {
                    viewModel.uiState.showingStudyView = false
                })
                let container = modelContext.container
                let service = StudyService(modelContainer: container)
                let studyVM = StudyViewModel(
                    cardSet: cardSet,
                    modelContext: modelContext,
                    service: service,
                    coordinator: coordinator
                )
                StudyView(viewModel: studyVM)
            }
        }
        #endif
        #if os(iOS)
        .fullScreenCover(isPresented: $viewModel.uiState.showingAutoView) {
            if let cardSet = viewModel.uiState.selectedCardSet {
                // Initialize MVVM+ Stack for AutoPlay
                let coordinator = AutoPlayCoordinator(onDismiss: {
                    viewModel.uiState.showingAutoView = false
                })
                
                // Reuse or create Service
                let container = modelContext.container
                let service = StudyService(modelContainer: container)
                
                let autoVM = AutoPlayViewModel(
                    cardSet: cardSet,
                    modelContext: modelContext,
                    service: service,
                    coordinator: coordinator
                )
                
                AutoPlayView(viewModel: autoVM)
            }
        }
        #else
        .sheet(isPresented: $viewModel.uiState.showingAutoView) {
            if let cardSet = viewModel.uiState.selectedCardSet {
                let coordinator = AutoPlayCoordinator(onDismiss: {
                    viewModel.uiState.showingAutoView = false
                })
                let container = modelContext.container
                let service = StudyService(modelContainer: container)
                let autoVM = AutoPlayViewModel(
                    cardSet: cardSet,
                    modelContext: modelContext,
                    service: service,
                    coordinator: coordinator
                )
                AutoPlayView(viewModel: autoVM)
            }
        }
        #endif
        #if os(iOS)
        .fullScreenCover(isPresented: $viewModel.uiState.showingSessionStats) {
            SessionStatsView()
                .presentationBackground(.ultraThinMaterial)
        }
        .fullScreenCover(isPresented: $viewModel.uiState.showingMasteryDashboard) {
            MasteryDashboardView(modelContext: modelContext)
                .presentationBackground(.ultraThinMaterial)
        }
        .fullScreenCover(isPresented: $viewModel.uiState.showingImport) {
            let coordinator = BrowseCoordinator(onDismiss: {
                viewModel.uiState.showingImport = false
            })
            let importVM = ImportViewModel(modelContext: modelContext, coordinator: coordinator)
            ImportView(viewModel: importVM)
                .presentationBackground(.ultraThinMaterial)
        }
        .fullScreenCover(isPresented: $viewModel.uiState.showingSettings) {
            SettingsView()
                .presentationBackground(.ultraThinMaterial)
        }
        #else
        .sheet(isPresented: $viewModel.uiState.showingSessionStats) {
            SessionStatsView()
        }
        .sheet(isPresented: $viewModel.uiState.showingMasteryDashboard) {
            MasteryDashboardView(modelContext: modelContext)
        }
        .sheet(isPresented: $viewModel.uiState.showingImport) {
            let coordinator = BrowseCoordinator(onDismiss: {
                viewModel.uiState.showingImport = false
            })
            let importVM = ImportViewModel(modelContext: modelContext, coordinator: coordinator)
            ImportView(viewModel: importVM)
        }
        .sheet(isPresented: $viewModel.uiState.showingSettings) {
            SettingsView()
        }
        #endif
        #if os(iOS)
        .fullScreenCover(item: $viewModel.uiState.browseCardSet) { deck in
            let coordinator = BrowseCoordinator(onDismiss: {
                viewModel.uiState.browseCardSet = nil
            })
            
            let vm = DeckDetailViewModel(
                cardSet: deck,
                service: cardService,
                coordinator: coordinator
            )
            
            DeckDetailView(viewModel: vm, coordinator: coordinator)
                .presentationBackground(.ultraThinMaterial)
        }
        #else
        .sheet(item: $viewModel.uiState.browseCardSet) { deck in
            let coordinator = BrowseCoordinator(onDismiss: {
                viewModel.uiState.browseCardSet = nil
            })
            let vm = DeckDetailViewModel(
                cardSet: deck,
                service: cardService,
                coordinator: coordinator
            )
            DeckDetailView(viewModel: vm, coordinator: coordinator)
        }
        #endif
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
        #if os(iOS)
        .fullScreenCover(isPresented: $viewModel.uiState.showingOnboarding) {
            OnboardingView {
                UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                hasSeenOnboarding = true
                viewModel.uiState.showingOnboarding = false
            }
        }
        #else
        .sheet(isPresented: $viewModel.uiState.showingOnboarding) {
            OnboardingView {
                UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                hasSeenOnboarding = true
                viewModel.uiState.showingOnboarding = false
            }
        }
        #endif
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
                // Refactored to use injected CardService
                DeckListView(selectedSet: $viewModel.uiState.selectedCardSet, service: cardService)
                    .onAppear {
                        logger.info("ContentView: Showing Refactored DeckListView")
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

    private func errorStateView(error: LocalizedError) -> some View {
        VStack(spacing: theme.metrics.emptyStateVerticalSpacing) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: theme.metrics.emptyStateIconSize))
                .foregroundColor(theme.colors.danger)
            
            Text("Failed to Load Decks")
                .font(.headline)
                .foregroundColor(theme.colors.textPrimary)
                .dynamicTypeSize(.large ... .accessibility5)
            
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
                .dynamicTypeSize(.large ... .accessibility5)
                .padding(.horizontal)
            
            Button {
                Task {
                    await viewModel.refreshCardSets()
                }
            } label: {
                Text("Try Again")
                    .font(.headline)
                    .foregroundColor(theme.colors.textPrimary)
                    .padding(.horizontal, theme.metrics.emptyStateButtonHorizontalPadding)
                    .padding(.vertical, theme.metrics.emptyStateButtonVerticalPadding)
                    .background(theme.gradients.accent)
                    .clipShape(RoundedRectangle(cornerRadius: theme.metrics.emptyStateButtonCornerRadius))
                    .dynamicTypeSize(.large ... .accessibility5)
            }
        }
        .padding(.horizontal, theme.metrics.emptyStateHorizontalPadding)
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
                    #if os(iOS)
                    UIImpactFeedbackGenerator.mediumImpact()
                    #endif
                    viewModel.addCardSet()
                }) {
                    Label(viewModel.uiState.isCreatingDeck ? "Creating..." : "Create New Deck", systemImage: "plus")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, theme.metrics.emptyStateButtonVerticalPadding)
                        .background(theme.gradients.accent)
                        .foregroundColor(theme.colors.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: theme.metrics.emptyStateButtonCornerRadius, style: .continuous))
                        .dynamicTypeSize(.large ... .accessibility5)
                }
                .disabled(viewModel.uiState.isCreatingDeck || viewModel.uiState.isReimporting)

                Button(action: {
                    #if os(iOS)
                    UIImpactFeedbackGenerator.lightImpact()
                    #endif
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
                #if os(iOS)
                UIImpactFeedbackGenerator.mediumImpact()
                #endif
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
    ContentView(modelContext: PersistenceController.preview.container.mainContext)
        .modelContainer(PersistenceController.preview.container)
        .environmentObject(TTSService.shared)
}
