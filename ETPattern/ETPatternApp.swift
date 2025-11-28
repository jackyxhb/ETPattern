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
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
