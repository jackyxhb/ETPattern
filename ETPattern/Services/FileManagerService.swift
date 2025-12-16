//
//  FileManagerService.swift
//  ETPattern
//
//  Created by admin on 28/11/2025.
//

import Foundation

class FileManagerService {
    private static var resourceBundle: Bundle {
        // In unit tests, Bundle.main may be the test runner bundle.
        // Prefer Bundle.main if it contains the CSVs, otherwise fall back to the bundle
        // that contains this type (the app/module bundle).
        if Bundle.main.url(forResource: "Group1", withExtension: "csv") != nil {
            return Bundle.main
        }
        return Bundle(for: FileManagerService.self)
    }

    static func getBundledCSVFiles() -> [String] {
        // Return the list of bundled CSV files (Group1.csv through Group12.csv)
        return (1...12).map { "Group\($0)" }
    }

    static func loadBundledCSV(named fileName: String) -> String? {
        guard let url = resourceBundle.url(forResource: fileName, withExtension: "csv") else {
            return nil
        }

        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            print("Error loading bundled CSV \(fileName): \(error)")
            return nil
        }
    }

    static func getCardSetName(from fileName: String) -> String {
        // Convert "Group1" to "Group 1" for display
        if fileName.hasPrefix("Group") {
            let number = fileName.replacingOccurrences(of: "Group", with: "")
            return "Group \(number)"
        }
        return fileName
    }
}