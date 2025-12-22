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

    // MARK: - Data Fetching
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CardSet.createdDate, ascending: false)],
        animation: .default)
    private var cardSets: FetchedResults<CardSet>

    @StateObject private var viewModel: ContentViewModel

    // MARK: - Onboarding State
    @State private var hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")

    init() {
        _viewModel = StateObject(wrappedValue: ContentViewModel(viewContext: PersistenceController.shared.container.viewContext))
    }

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
            NavigationView {
                SessionStatsView()
                    .navigationTitle("Session Stats")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { viewModel.uiState.showingSessionStats = false }
                        }
                    }
                    .toolbarBackground(.ultraThinMaterial.opacity(0.8), for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
                    .toolbarColorScheme(.dark, for: .navigationBar)
                }
        }
        .sheet(isPresented: $viewModel.uiState.showingImport) {
            NavigationView {
                ImportView()
                    .navigationTitle("Import")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { viewModel.uiState.showingImport = false }
                        }
                    }
                    .toolbarBackground(.ultraThinMaterial.opacity(0.8), for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
                    .toolbarColorScheme(.dark, for: .navigationBar)
                }
        }
        .sheet(isPresented: $viewModel.uiState.showingSettings) {
            NavigationView {
                SettingsView()
                    .navigationTitle("Settings")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { viewModel.uiState.showingSettings = false }
                        }
                    }
                    .toolbarBackground(.ultraThinMaterial.opacity(0.8), for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
                    .toolbarColorScheme(.dark, for: .navigationBar)
                }
        }
        .sheet(item: $viewModel.uiState.browseCardSet) { deck in
            NavigationView {
                DeckDetailView(cardSet: deck)
                    .navigationTitle(deck.name ?? "Deck Details")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { viewModel.uiState.browseCardSet = nil }
                        }
                    }
                    .toolbarBackground(.ultraThinMaterial.opacity(0.8), for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
                    .toolbarColorScheme(.dark, for: .navigationBar)
                }
        }
        .alert("Rename Deck", isPresented: $viewModel.uiState.showingRenameAlert) {
            TextField("Deck Name", text: $viewModel.uiState.newName)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                viewModel.performRename()
            }
        }
        .alert("Delete Deck", isPresented: $viewModel.uiState.showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                viewModel.performDelete()
            }
        } message: {
            Text("Are you sure you want to delete this deck? This action cannot be undone.")
        }
        .alert("Export Deck", isPresented: $viewModel.uiState.showingExportAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Export") {
                if let cardSet = viewModel.uiState.selectedCardSet {
                    viewModel.exportDeck(cardSet)
                }
            }
        } message: {
            Text("Export this deck as a CSV file?")
        }
        .alert("Re-import Deck", isPresented: $viewModel.uiState.showingReimportAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Re-import", role: .destructive) {
                viewModel.performReimport()
            }
        } message: {
            Text("This will replace all cards in the deck with the source CSV.")
        }
        .fileImporter(
            isPresented: $viewModel.uiState.showingReimportFilePicker,
            allowedContentTypes: [UTType.commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            viewModel.handleReimportFileSelection(result)
        }
        .alert(viewModel.uiState.errorTitle, isPresented: $viewModel.uiState.showErrorAlert) {
            Button("OK", role: .cancel) {}
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
                if cardSets.isEmpty {
                    emptyStateView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    DeckListView(viewModel: viewModel, cardSets: cardSets)
                }
            }
        }
        .padding(.horizontal, theme.metrics.contentHorizontalPadding)
        .padding(.top, theme.metrics.contentTopPadding)
    }

    private var emptyStateView: some View {
        SharedEmptyStateView(
            title: "No Decks Yet",
            description: "Create your first flashcard deck or import CSV files to get started with learning English patterns.",
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
                    title: "Study", systemImage: "book", gradient: theme.gradients.accent,
                    action: onStudy)
                ActionButton(
                    title: "Auto", systemImage: "waveform", gradient: theme.gradients.success,
                    action: onAuto)
                ActionButton(
                    title: "Browse", systemImage: "list.bullet", gradient: theme.gradients.neutral,
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
