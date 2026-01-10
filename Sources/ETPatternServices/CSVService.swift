//
//  CSVService.swift
//  ETPattern
//
//  Created by AI Agent on 22/12/2025.
//

import Foundation
import SwiftData
import UniformTypeIdentifiers
import ETPatternModels
import ETPatternCore

/// Service protocol for CSV import/export operations
@MainActor
public protocol CSVServiceProtocol {
    func exportCardSet(_ cardSet: CardSet) throws -> String
    func reimportBundledDeck(_ cardSet: CardSet, kind: CSVService.BundledDeckKind) async throws -> (importedCount: Int, failures: [String])
    func reimportCustomDeck(_ cardSet: CardSet, from url: URL) async throws -> Int
}

/// Service for handling CSV import/export operations
@MainActor
public class CSVService: CSVServiceProtocol {
    private let csvImporter: CSVImporter
    private let modelContext: ModelContext

    public enum BundledDeckKind {
        case master
        case group(fileName: String)
    }

    public init(modelContext: ModelContext, csvImporter: CSVImporter) {
        self.modelContext = modelContext
        self.csvImporter = csvImporter
    }

    public func exportCardSet(_ cardSet: CardSet) throws -> String {
        var csvContent = "Front;;Back;;Tags\n"

        for card in cardSet.cards.sorted(by: { $0.front < $1.front }) {
            let front = card.front.replacingOccurrences(of: "\"", with: "\"\"")
            let back = card.back.replacingOccurrences(of: "\"", with: "\"\"").replacingOccurrences(of: "\n", with: "<br>")
            let tags = (card.tags ?? "").replacingOccurrences(of: "\"", with: "\"\"")

            csvContent += "\"\(front)\";;\"\(back)\";;\"\(tags)\"\n"
        }

        return csvContent
    }

    public func reimportBundledDeck(_ cardSet: CardSet, kind: BundledDeckKind) async throws -> (importedCount: Int, failures: [String]) {
        deleteAllCards(in: cardSet)

        var importedCount = 0
        var failures: [String] = []

        switch kind {
        case .master:
            cardSet.name = Constants.Decks.bundledMasterName
            let bundledFiles = FileManagerService.getBundledCSVFiles()

            for fileName in bundledFiles {
                guard let content = FileManagerService.loadBundledCSV(named: fileName) else {
                    failures.append(fileName)
                    continue
                }
                let cards = self.csvImporter.parseCSV(content, cardSetName: Constants.Decks.bundledMasterName)
                for card in cards {
                    card.cardSet = cardSet
                    cardSet.cards.append(card)
                    modelContext.insert(card)
                }
                importedCount += cards.count
            }

        case .group(let fileName):
            guard let content = FileManagerService.loadBundledCSV(named: fileName) else {
                throw CSVServiceError.bundledFileNotFound(fileName)
            }
            let cards = self.csvImporter.parseCSV(content, cardSetName: cardSet.name)
            for card in cards {
                card.cardSet = cardSet
                cardSet.cards.append(card)
                modelContext.insert(card)
            }
            importedCount = cards.count
        }

        try modelContext.save()
        return (importedCount, failures)
    }

    public func reimportCustomDeck(_ cardSet: CardSet, from url: URL) async throws -> Int {
        guard url.startAccessingSecurityScopedResource() else {
            throw CSVServiceError.securityScopedAccessFailed
        }
        defer { url.stopAccessingSecurityScopedResource() }

        let content = try String(contentsOf: url, encoding: .utf8)
        let cards = self.csvImporter.parseCSV(content, cardSetName: cardSet.name)

        guard !cards.isEmpty else {
            throw CSVServiceError.noValidCardsFound
        }

        deleteAllCards(in: cardSet)
        for card in cards {
            card.cardSet = cardSet
            cardSet.cards.append(card)
            modelContext.insert(card)
        }
        
        try modelContext.save()
        return cards.count
    }

    private func deleteAllCards(in cardSet: CardSet) {
        for card in cardSet.cards {
            modelContext.delete(card)
        }
        cardSet.cards.removeAll()
    }

    public func bundledDeckKind(for cardSet: CardSet) -> BundledDeckKind? {
        let name = cardSet.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if name == Constants.Decks.bundledMasterName || name == Constants.Decks.legacyBundledMasterName {
            return .master
        }
        if name.hasPrefix("Group "),
           let number = Int(name.replacingOccurrences(of: "Group ", with: "")),
           (1...12).contains(number) {
            return .group(fileName: "Group\(number)")
        }
        return nil
    }
}


// MARK: - CSV Service Errors
public enum CSVServiceError: LocalizedError {
    case bundledFileNotFound(String)
    case securityScopedAccessFailed
    case noValidCardsFound
    case cardSetNotFound

    public var errorDescription: String? {
        switch self {
        case .bundledFileNotFound(let fileName):
            return "Failed to load bundled CSV \(fileName)."
        case .securityScopedAccessFailed:
            return "Cannot access the selected file."
        case .noValidCardsFound:
            return "No valid cards found in the CSV file. Please check the format."
        case .cardSetNotFound:
            return "The card set could not be found."
        }
    }
}