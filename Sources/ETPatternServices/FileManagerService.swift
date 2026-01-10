//
//  FileManagerService.swift
//  ETPattern
//
//  Created by admin on 28/11/2025.
//

import Foundation

public class FileManagerService {
    public static func getBundledCSVFiles() -> [String] {
        let bundle = Bundle.main
        let paths = bundle.paths(forResourcesOfType: "csv", inDirectory: nil)
        return paths.map { ($0 as NSString).lastPathComponent.replacingOccurrences(of: ".csv", with: "") }
            .filter { !$0.hasPrefix("Group_") }
    }

    public static func loadBundledCSV(named fileName: String) -> String? {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "csv") else {
            return nil
        }

        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
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