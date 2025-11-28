//
//  ETPatternApp.swift
//  ETPattern
//
//  Created by admin on 25/11/2025.
//

import SwiftUI
import CoreData

@main
struct ETPatternApp: App {
    let persistenceController = PersistenceController.shared

    init() {
        // Initialize bundled card sets on first launch
        persistenceController.initializeBundledCardSets()
        
        // Initialize default settings if not already set
        initializeDefaultSettings()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
    
    private func initializeDefaultSettings() {
        let defaults = UserDefaults.standard
        
        // Set default card order mode if not already set
        if defaults.string(forKey: "cardOrderMode") == nil {
            defaults.set("random", forKey: "cardOrderMode")
        }
        
        // Set default voice if not already set
        if defaults.string(forKey: "selectedVoice") == nil {
            defaults.set("en-US", forKey: "selectedVoice")
        }
    }
}
