//
//  ContentView.swift
//  ETPattern
//
//  Created by admin on 25/11/2025.
//

import SwiftUI
import SwiftData
import os.log

// MARK: - Root Coordinator View

struct ContentView: View {
    @Environment(\.theme) var theme
    @Environment(\.modelContext) private var modelContext
    
    // Core Infrastructure
    @State private var coordinator = AppCoordinator()
    
    // ViewModels
    @State private var dashboardViewModel: DashboardViewModel?
    
    private let logger = Logger(subsystem: "com.jack.ETPattern", category: "ContentView")
    
    // Dependencies
    // We initialize these in onAppear to ensure ModelContext is ready if needed, 
    // though creating Service here is fine.
    
    init(modelContext: ModelContext) {
        // We don't need to do much here anymore as we shift to on-demand init
    }
    
    var body: some View {
        Group {
            if let viewModel = dashboardViewModel {
                NavigationStack(path: $coordinator.path) {
                    DashboardView(viewModel: viewModel)
                        .navigationDestination(for: CardSet.self) { deck in
                             // Fallback or specific detail view if pushed
                             DeckDetailView(cardSet: deck)
                        }
                }
                .sheet(item: $coordinator.sheet) { destination in
                    switch destination {
                    case .settings:
                        SettingsView()
                            .presentationBackground(.ultraThinMaterial)
                    case .browse(let deck):
                        DeckDetailView(cardSet: deck)
                            .presentationBackground(.ultraThinMaterial)
                    }
                }
                .fullScreenCover(item: $coordinator.fullScreenCover) { destination in
                    switch destination {
                    case .study(let deck):
                        StudyView(cardSet: deck, modelContext: modelContext)
                    case .autoPlay(let deck):
                        AutoPlayView(cardSet: deck, modelContext: modelContext)
                    case .masteryDashboard:
                        MasteryDashboardView(modelContext: modelContext)
                            .presentationBackground(.ultraThinMaterial)
                    case .importCSV:
                        ImportView(modelContext: modelContext)
                            .presentationBackground(.ultraThinMaterial)
                    case .sessionStats:
                        SessionStatsView()
                            .presentationBackground(.ultraThinMaterial)
                    case .onboarding:
                        OnboardingView {
                            coordinator.dismissFullScreen()
                        }
                    }
                }
            } else {
                // Bootstrapping State
                ProgressView()
                    .onAppear {
                        bootstrap()
                    }
            }
        }
        .environment(coordinator) // Inject for child views
    }
    
    private func bootstrap() {
        // Initialize the Core Service Layer
        let service = CardSetService(modelContext: modelContext)
        
        // Initialize the Root ViewModel
        // Note: In a larger app, a DependencyContainer would handle this
        let vm = DashboardViewModel(service: service, coordinator: coordinator)
        
        self.dashboardViewModel = vm
    }
}
