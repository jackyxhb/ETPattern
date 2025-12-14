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
                card.front = front
                card.back = back
                card.tags = tags
                card.difficulty = 0
                card.nextReviewDate = Date()
                card.interval = 1
                card.easeFactor = 2.5
                cards.append(card)
                lineNumber += 1
            }
        }

        return cards
    }

    func importBundledCSV(named fileName: String, cardSetName: String) -> CardSet? {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "csv") else {
            print("Could not find bundled CSV file: \(fileName)")
            return nil
        }

        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let cards = parseCSV(content, cardSetName: cardSetName)

            let cardSet = CardSet(context: viewContext)
            cardSet.name = cardSetName
            cardSet.createdDate = Date()

            // Sort cards by ID to ensure proper order
            let sortedCards = cards.sorted { $0.id < $1.id }
            cardSet.addToCards(NSSet(array: sortedCards))

            // Set the cardSet relationship for each card
            for card in sortedCards {
                card.cardSet = cardSet
            }

            try viewContext.save()
            return cardSet
        } catch {
            print("Error importing CSV: \(error)")
            return nil
        }
    }
}