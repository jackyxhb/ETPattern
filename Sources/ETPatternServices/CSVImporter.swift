//
//  CSVImporter.swift
//  ETPattern
//
//  Created by admin on 28/11/2025.
//

import Foundation
import SwiftData
import ETPatternModels
import ETPatternCore

public class CSVImporter {
    private let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    public func parseCSV(_ content: String, cardSetName: String) -> [Card] {
        let lines = content.components(separatedBy: .newlines)
        var cards: [Card] = []
        var lineNumber = 1 // Start from 1 since we skip the header

        for line in lines.dropFirst() { // Skip header
            let components = line.components(separatedBy: ";;")
            guard components.count >= 2 else { continue }

            let front = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let back = components[1].replacingOccurrences(of: "<br>", with: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            let tags = components.count > 2 ? components[2].trimmingCharacters(in: .whitespacesAndNewlines) : ""

            if !front.isEmpty && !back.isEmpty {
                let card = Card(
                    id: 0, // ID will be assigned later in Persistence to ensure uniqueness
                    front: front,
                    back: back,
                    cardName: front,
                    groupId: 0,
                    groupName: ""
                )
                card.tags = tags

                // Parse groupId and groupName from tags
                if !tags.isEmpty {
                    // Find the first dash after a number (e.g., "2-Agree-Disagree")
                    if let range = tags.range(of: #"^\d+-"#,
                                            options: .regularExpression) {
                        let groupIdString = String(tags[..<range.upperBound].dropLast()) // Remove the dash
                        if let groupIdValue = Int32(groupIdString) {
                            card.groupId = groupIdValue
                        }
                        card.groupName = String(tags[range.upperBound...]) // Everything after the first dash
                    } else {
                        // If no number-dash pattern, use default values
                        card.groupId = 0
                        card.groupName = tags
                    }
                }

                cards.append(card)
                lineNumber += 1
            }
        }

        return cards
    }

    public func importBundledCSV(named fileName: String, cardSetName: String) throws -> CardSet {
        // Note: Using Bundle.main here assumes the app provides the resources.
        // In a modular setup, we might need to pass the bundle or use a specific one.
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "csv") else {
            throw CSVImporterError.csvFileNotFound(fileName: fileName)
        }

        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let cards = parseCSV(content, cardSetName: cardSetName)

            if cards.isEmpty {
                throw CSVImporterError.csvParsingFailed(reason: "No valid cards found in \(fileName)")
            }

            let cardSet = CardSet(name: cardSetName)
            modelContext.insert(cardSet)

            // Sort cards by ID to ensure proper order
            let sortedCards = cards.sorted { $0.id < $1.id }
            
            // Set the cardSet relationship for each card
            for card in sortedCards {
                card.cardSet = cardSet
                cardSet.cards.append(card)
                modelContext.insert(card)
            }

            try modelContext.save()
            return cardSet
        } catch let error as CSVImporterError {
            throw error
        } catch {
            throw CSVImporterError.csvImportFailed(reason: error.localizedDescription)
        }
    }
}

public enum CSVImporterError: LocalizedError {
    case csvFileNotFound(fileName: String)
    case csvParsingFailed(reason: String)
    case csvImportFailed(reason: String)

    public var errorDescription: String? {
        switch self {
        case .csvFileNotFound(let fileName):
            return "CSV file not found: \(fileName)"
        case .csvParsingFailed(let reason):
            return "CSV parsing failed: \(reason)"
        case .csvImportFailed(let reason):
            return "CSV import failed: \(reason)"
        }
    }
}