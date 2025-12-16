//
//  CSVImporter.swift
//  ETPattern
//
//  Created by admin on 28/11/2025.
//

import Foundation
import CoreData

class CSVImporter {
    private let viewContext: NSManagedObjectContext

    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }

    func parseCSV(_ content: String, cardSetName: String) -> [Card] {
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
                let card = Card(context: viewContext)
                card.id = Int32(lineNumber) // Assign ID based on line number
                card.cardName = front  // Store the original pattern string
                card.front = front     // Set front to the same value
                card.back = back
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
                } else {
                    card.groupId = 0
                    card.groupName = ""
                }
                
                card.difficulty = 0
                card.nextReviewDate = Date()
                card.interval = Constants.SpacedRepetition.initialInterval
                card.easeFactor = Constants.SpacedRepetition.defaultEaseFactor
                cards.append(card)
                lineNumber += 1
            }
        }

        return cards
    }

    func importBundledCSV(named fileName: String, cardSetName: String) throws -> CardSet {
        guard let content = FileManagerService.loadBundledCSV(named: fileName) else {
            throw AppError.csvFileNotFound(fileName: fileName)
        }

        do {
            let cards = parseCSV(content, cardSetName: cardSetName)

            if cards.isEmpty {
                throw AppError.csvParsingFailed(reason: "No valid cards found in \(fileName)")
            }

            let fetchRequest: NSFetchRequest<CardSet> = CardSet.fetchRequest()
            fetchRequest.fetchLimit = 1
            fetchRequest.predicate = NSPredicate(format: "name == %@", cardSetName)

            let cardSet: CardSet
            if let existingDeck = (try? viewContext.fetch(fetchRequest))?.first {
                cardSet = existingDeck
            } else {
                let newDeck = CardSet(context: viewContext)
                newDeck.name = cardSetName
                newDeck.createdDate = Date()
                cardSet = newDeck
            }

            // Sort cards by ID to ensure proper order
            let sortedCards = cards.sorted { $0.id < $1.id }
            cardSet.addToCards(NSSet(array: sortedCards))

            // Set the cardSet relationship for each card
            for card in sortedCards {
                card.cardSet = cardSet
            }

            try viewContext.save()
            return cardSet
        } catch let error as AppError {
            throw error
        } catch {
            throw AppError.csvImportFailed(reason: error.localizedDescription)
        }
    }
}