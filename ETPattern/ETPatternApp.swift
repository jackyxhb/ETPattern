//
//  ETPatternApp.swift
//  ETPattern
//
//  Created by admin on 25/11/2025.
//

import SwiftUI
import SwiftData
import Combine

@main
struct ETPatternApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var systemColorScheme

    var currentTheme: Theme {
        switch themeManager.currentTheme {
        case .light: return Theme.light
        case .dark: return Theme.dark
        case .system:
            return systemColorScheme == .dark ? Theme.dark : Theme.light
        }
    }

    init() {
        // Initialize default settings if not already set
        initializeDefaultSettings()
    }

    var body: some Scene {
        WindowGroup {
            SplashHostView {
                ContentView(modelContext: persistenceController.container.mainContext)
            }
            .modelContainer(persistenceController.container)
            .environmentObject(TTSService.shared)
            .environmentObject(CloudSyncManager.shared) // Safe to inject even if unused
            .environmentObject(themeManager)
            .environment(\.theme, currentTheme)
            .preferredColorScheme(themeManager.colorScheme)
        }
    }

    private func initializeDefaultSettings() {
        let defaults = UserDefaults.standard

        // Set default card order mode if not already set
        if defaults.string(forKey: "cardOrderMode") == nil {
            defaults.set("random", forKey: "cardOrderMode")
        }

        // Set default autoplay order mode if not already set
        if defaults.string(forKey: "autoPlayOrderMode") == nil {
            defaults.set("sequential", forKey: "autoPlayOrderMode")
        }

        // Set default voice if not already set
        if defaults.string(forKey: "selectedVoice") == nil {
            defaults.set("en-US", forKey: "selectedVoice")
        }

        // Set default TTS percentage if not already set
        if defaults.float(forKey: "ttsPercentage") == 0 {
            defaults.set(Constants.TTS.defaultPercentage, forKey: "ttsPercentage")
        }
    }
}

@MainActor
class AppInitManager: ObservableObject {
    @Published var isReady = false
    @Published var statusMessage = "Initializing..."
    
    static let shared = AppInitManager()
    
    private init() {}
    
    func initializeApp() async {
        statusMessage = "Preparing learning materials..."
        
        // Wait for persistence to verify/seed data
        // Uses force: false to respect existing data, but ensures check happens
        let result = await PersistenceController.shared.initializeBundledCardSets(force: false)
        print("🚀 AppInit: \(result)")
        
        // Artificial delay for branding if needed, but data is priority
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second minimum splash
        
        withAnimation {
            isReady = true
        }
    }
}
