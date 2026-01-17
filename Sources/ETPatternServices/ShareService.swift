//
//  ShareService.swift
//  ETPattern
//
//  Created by AI Agent on 22/12/2025.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Protocol for sharing operations
public protocol ShareServiceProtocol {
    func shareCSVContent(_ content: String, fileName: String) throws
}

/// Service for handling share operations
public class ShareService: ShareServiceProtocol {
    public init() {}
    
    public func shareCSVContent(_ content: String, fileName: String) throws {
        #if canImport(UIKit)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(fileName).csv")
        try content.write(to: tempURL, atomically: true, encoding: .utf8)

        let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
        #else
        print("ShareService: Sharing not supported on this platform.")
        #endif
    }
}