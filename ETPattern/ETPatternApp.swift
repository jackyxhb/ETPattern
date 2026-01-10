//
//  ETPatternApp.swift
//  ETPattern
//
//  Created by admin on 25/11/2025.
//

import SwiftUI
import SwiftData
import ETPatternServices
import ETPatternCore

@main
@available(iOS 18.0, *)
struct ETPatternApp: App {
    let persistenceController = PersistenceController.shared

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
            .environment(\.theme, Theme.default)
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
