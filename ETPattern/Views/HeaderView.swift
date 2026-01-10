//
//  HeaderView.swift
//  ETPattern
//
//  Created by admin on 25/11/2025.
//

import SwiftUI
import ETPatternServices

struct HeaderView: View {
    @ObservedObject var viewModel: ContentViewModel
    @Environment(\.theme) var theme

    var body: some View {
        HStack(alignment: .center, spacing: theme.metrics.headerMainSpacing) {
            Text("English Thought")
                .font(theme.metrics.title.bold())
                .foregroundColor(theme.colors.textPrimary)
                .dynamicTypeSize(.large ... .accessibility5)
            Spacer()
            cloudSyncStatus
            headerActions
        }
    }

    private var cloudSyncStatus: some View {
        HStack(spacing: 4) {
            if cloudSyncManager.isSyncing {
                Image(systemName: "icloud.and.arrow.down")
                    .symbolEffect(.pulse)
                    .foregroundColor(theme.colors.highlight)
            } else if let error = cloudSyncManager.syncError {
                Image(systemName: "icloud.slash")
                    .foregroundColor(theme.colors.danger)
                    .help(error.localizedDescription)
            } else {
                Image(systemName: "icloud")
                    .foregroundColor(theme.colors.textSecondary.opacity(0.5))
            }
        }
        .imageScale(.small)
        .font(.caption)
    }
    
    @EnvironmentObject private var cloudSyncManager: ETPatternServices.CloudSyncManager

    private var headerActions: some View {
        Button(action: {
            UIImpactFeedbackGenerator.lightImpact()
            viewModel.uiState.showingHeaderMenu = true
        }) {
            headerIcon(systemName: "ellipsis")
        }
        .popover(isPresented: $viewModel.uiState.showingHeaderMenu) {
            ZStack {
                theme.colors.surfaceElevated
                    .clipShape(RoundedRectangle(cornerRadius: theme.metrics.cornerRadius))
                    .shadow(color: theme.colors.shadow.opacity(0.3), radius: 10)
                VStack(spacing: 0) {
                    Button {
                        viewModel.uiState.showingMasteryDashboard = true
                        viewModel.uiState.showingHeaderMenu = false
                    } label: {
                        Label("Mastery Dashboard", systemImage: "sparkles")
                            .foregroundColor(theme.colors.onSurfaceElevated)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                    .buttonStyle(.plain)

                    Button {
                        viewModel.uiState.showingSessionStats = true
                        viewModel.uiState.showingHeaderMenu = false
                    } label: {
                        Label("Session Stats", systemImage: "chart.bar")
                            .foregroundColor(theme.colors.onSurfaceElevated)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                    .buttonStyle(.plain)

                    Button {
                        viewModel.uiState.showingImport = true
                        viewModel.uiState.showingHeaderMenu = false
                    } label: {
                        Label("Import", systemImage: "square.and.arrow.down")
                            .foregroundColor(theme.colors.onSurfaceElevated)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                    .buttonStyle(.plain)

                    Button {
                        viewModel.uiState.showingSettings = true
                        viewModel.uiState.showingHeaderMenu = false
                    } label: {
                        Label("Settings", systemImage: "gear")
                            .foregroundColor(theme.colors.onSurfaceElevated)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                    .buttonStyle(.plain)

                    Button {
                        viewModel.uiState.showingOnboarding = true
                        viewModel.uiState.showingHeaderMenu = false
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

    private func headerIcon(systemName: String) -> some View {
        Image(systemName: systemName)
            .imageScale(.medium)
            .foregroundColor(theme.colors.textPrimary)
            .padding(theme.metrics.headerIconPadding)
            .background(theme.colors.surfaceLight)
            .clipShape(Circle())
    }
}