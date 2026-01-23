//
//  ShareService.swift
//  ETPattern
//
//  Created by AI Agent on 22/12/2025.
//

import Foundation
import UIKit

/// Protocol for sharing operations
protocol ShareServiceProtocol {
    func shareCSVContent(_ content: String, fileName: String) throws
}

/// Service for handling share operations
class ShareService: ShareServiceProtocol {
    init() {}
    
    func shareCSVContent(_ content: String, fileName: String) throws {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(fileName).csv")
        try content.write(to: tempURL, atomically: true, encoding: .utf8)

        let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}