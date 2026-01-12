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
        .sheet(isPresented: $viewModel.uiState.showingHeaderMenu) {
            VStack(spacing: theme.metrics.smallSpacing) {
                menuButton(title: "Mastery Dashboard", icon: "sparkles") {
                    viewModel.uiState.showingMasteryDashboard = true
                    viewModel.uiState.showingHeaderMenu = false
                }

                menuButton(title: "Session Stats", icon: "chart.bar") {
                    viewModel.uiState.showingSessionStats = true
                    viewModel.uiState.showingHeaderMenu = false
                }

                menuButton(title: "Import", icon: "square.and.arrow.down") {
                    viewModel.uiState.showingImport = true
                    viewModel.uiState.showingHeaderMenu = false
                }

                menuButton(title: "Settings", icon: "gear") {
                    viewModel.uiState.showingSettings = true
                    viewModel.uiState.showingHeaderMenu = false
                }

                menuButton(title: "Onboarding", icon: "questionmark.circle") {
                    viewModel.uiState.showingOnboarding = true
                    viewModel.uiState.showingHeaderMenu = false
                }
            }
            .padding(theme.metrics.largeSpacing)
            .presentationDetents([.height(320)])
            .presentationDragIndicator(.visible)
            .themedPresentation()
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

    private func menuButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: theme.metrics.standardSpacing) {
                Image(systemName: icon)
                    .font(.body)
                    .frame(width: 24)
                Text(title)
                    .font(.body)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(theme.colors.textSecondary.opacity(0.5))
            }
            .foregroundColor(theme.colors.textPrimary) // Liquid Glass requirement: textPrimary on glass
            .padding()
            .background(theme.colors.surfaceLight) // Subtle card effect for each item
            .clipShape(RoundedRectangle(cornerRadius: theme.metrics.cornerRadius * 0.6, style: .continuous)) // Slightly smaller radius for inner items
        }
    }
}