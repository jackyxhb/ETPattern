//
//  CSVService.swift
//  ETPattern
//
//  Created by AI Agent on 22/12/2025.
//

import Foundation
import CoreData
import UniformTypeIdentifiers

// Import project modules
import class ETPattern.CSVImporter
import class ETPattern.FileManagerService
import struct ETPattern.Constants

/// Service protocol for CSV import/export operations
protocol CSVServiceProtocol {
    func exportCardSet(_ cardSet: CardSet) throws -> String
    func reimportBundledDeck(_ cardSet: CardSet, kind: CSVService.BundledDeckKind) async throws -> (importedCount: Int, failures: [String])
    func reimportCustomDeck(_ cardSet: CardSet, from url: URL) async throws -> Int
}

/// Service for handling CSV import/export operations
class CSVService: CSVServiceProtocol {
    private let csvImporter: CSVImporter
    private let mainContext: NSManagedObjectContext
    private let backgroundContextManager: BackgroundContextManager

    enum BundledDeckKind {
        case master
        case group(fileName: String)
    }

    init(viewContext: NSManagedObjectContext, csvImporter: CSVImporter, backgroundContextManager: BackgroundContextManager) {
        self.mainContext = viewContext
        self.csvImporter = csvImporter
        self.backgroundContextManager = backgroundContextManager
    }

    func exportCardSet(_ cardSet: CardSet) throws -> String {
        var csvContent = "Front;;Back;;Tags\n"

        if let cards = cardSet.cards as? Set<Card> {
            for card in cards.sorted(by: { ($0.front ?? "") < ($1.front ?? "") }) {
                let front = card.front?.replacingOccurrences(of: "\"", with: "\"\"") ?? ""
                let back = card.back?.replacingOccurrences(of: "\"", with: "\"\"").replacingOccurrences(of: "\n", with: "<br>") ?? ""
                let tags = card.tags?.replacingOccurrences(of: "\"", with: "\"\"") ?? ""

                csvContent += "\"\(front)\";;\"\(back)\";;\"\(tags)\"\n"
            }
        }

        return csvContent
    }

    func reimportBundledDeck(_ cardSet: CardSet, kind: BundledDeckKind) async throws -> (importedCount: Int, failures: [String]) {
        let cardSetObjectID = cardSet.objectID

        return try await backgroundContextManager.performBackgroundTask { [self] context in
            guard let backgroundCardSet = context.object(with: cardSetObjectID) as? CardSet else {
                throw CSVServiceError.cardSetNotFound
            }

            deleteAllCards(in: backgroundCardSet, context: context)

            var importedCount = 0
            var failures: [String] = []

            switch kind {
            case .master:
                backgroundCardSet.name = Constants.Decks.bundledMasterName
                let bundledFiles = FileManagerService.getBundledCSVFiles()

                for fileName in bundledFiles {
                    guard let content = FileManagerService.loadBundledCSV(named: fileName) else {
                        failures.append(fileName)
                        continue
                    }
                    let cards = self.csvImporter.parseCSV(content, cardSetName: Constants.Decks.bundledMasterName)
                    for card in cards {
                        card.cardSet = backgroundCardSet
                        backgroundCardSet.addToCards(card)
                    }
                    importedCount += cards.count
                }

            case .group(let fileName):
                guard let content = FileManagerService.loadBundledCSV(named: fileName) else {
                    throw CSVServiceError.bundledFileNotFound(fileName)
                }
                let cards = self.csvImporter.parseCSV(content, cardSetName: backgroundCardSet.name ?? "")
                for card in cards {
                    card.cardSet = backgroundCardSet
                    backgroundCardSet.addToCards(card)
                }
                importedCount = cards.count
            }

            return (importedCount, failures)
        }
    }

    func reimportCustomDeck(_ cardSet: CardSet, from url: URL) async throws -> Int {
        let cardSetObjectID = cardSet.objectID

        return try await backgroundContextManager.performBackgroundTask { [self] context in
            guard let backgroundCardSet = context.object(with: cardSetObjectID) as? CardSet else {
                throw CSVServiceError.cardSetNotFound
            }

            guard url.startAccessingSecurityScopedResource() else {
                throw CSVServiceError.securityScopedAccessFailed
            }
            defer { url.stopAccessingSecurityScopedResource() }

            let content = try String(contentsOf: url, encoding: .utf8)
            let cards = self.csvImporter.parseCSV(content, cardSetName: backgroundCardSet.name ?? "")

            guard !cards.isEmpty else {
                throw CSVServiceError.noValidCardsFound
            }

            deleteAllCards(in: backgroundCardSet, context: context)
            for card in cards {
                card.cardSet = backgroundCardSet
                backgroundCardSet.addToCards(card)
            }

            return cards.count
        }
    }

    private func deleteAllCards(in cardSet: CardSet, context: NSManagedObjectContext) {
        if let cards = cardSet.cards as? Set<Card> {
            for card in cards {
                context.delete(card)
            }
        }
    }

    func bundledDeckKind(for cardSet: CardSet) -> BundledDeckKind? {
        let name = (cardSet.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
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
enum CSVServiceError: LocalizedError {
    case bundledFileNotFound(String)
    case securityScopedAccessFailed
    case noValidCardsFound
    case cardSetNotFound

    var errorDescription: String? {
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