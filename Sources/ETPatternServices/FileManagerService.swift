//
//  FileManagerService.swift
//  ETPattern
//
//  Created by admin on 28/11/2025.
//

import Foundation

public class FileManagerService {
    
    /// Returns the bundle containing the app's resources.
    /// For SwiftPM built as Xcode project, resources are in a nested bundle.
    private static var resourceBundle: Bundle {
        // Check for the nested resource bundle (SwiftPM executable built via Xcode)
        if let resourceBundleURL = Bundle.main.url(forResource: "ETPattern_ETPatternApp", withExtension: "bundle"),
           let bundle = Bundle(url: resourceBundleURL) {
            return bundle
        }
        // Fallback to main bundle (traditional Xcode project)
        return Bundle.main
    }
    
    public static func getBundledCSVFiles() -> [String] {
        let bundle = resourceBundle
        let paths = bundle.paths(forResourcesOfType: "csv", inDirectory: nil)
        return paths.map { ($0 as NSString).lastPathComponent.replacingOccurrences(of: ".csv", with: "") }
            .filter { !$0.hasPrefix("Group_") }
    }

    public static func loadBundledCSV(named fileName: String) -> String? {
        let bundle = resourceBundle
        guard let url = bundle.url(forResource: fileName, withExtension: "csv") else {
            print("⚠️ FileManagerService: Could not find \(fileName).csv in bundle: \(bundle.bundlePath)")
            return nil
        }

        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            print("❌ FileManagerService: Error reading \(fileName).csv: \(error)")
            return nil
        }
    }

    public static func getCardSetName(from fileName: String) -> String {
        // Convert "Group1" to "Group 1" for display
        if fileName.hasPrefix("Group") {
            let number = fileName.replacingOccurrences(of: "Group", with: "")
            return "Group \(number)"
        }
        return fileName
    }
}