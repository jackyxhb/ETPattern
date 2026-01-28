//
//  CardFaceViewModel.swift
//  ETPattern
//
//  Extracted from SharedViews.swift for testability.
//

import Foundation
import SwiftUI
import Translation
import Combine
import os

@MainActor
final class CardFaceViewModel: ObservableObject {
    @Published var translations: [String: String] = [:]
    @Published var sentences: [String] = []

    private let logger = Logger(subsystem: "com.jack.ETPattern", category: "CardFaceViewModel")

    func setup(text: String, isFront: Bool) {
        if isFront {
            let separators = CharacterSet(charactersIn: ".!?\n")
            let components = text.components(separatedBy: separators)
            self.sentences = components.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        } else {
            self.sentences = text.components(separatedBy: "\n").filter { !$0.isEmpty }
        }
    }

    func updateTranslations(_ newTranslations: [String: String]) {
        self.translations = newTranslations
        logger.info("Translations updated: \(self.translations.count) items")
    }
}
