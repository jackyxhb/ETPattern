//
//  CardSetRepository.swift
//  ETPattern
//
//  Created by AI Agent on 22/12/2025.
//

import Foundation
import SwiftData

/// Repository protocol for CardSet data operations
@MainActor
protocol CardSetRepositoryProtocol {
    func createCardSet(name: String) async throws -> CardSet
    func deleteCardSet(_ cardSet: CardSet) async throws
    func updateCardSetName(_ cardSet: CardSet, newName: String) async throws
    func fetchCardSets() -> [CardSet]
}

/// SwiftData repository for CardSet operations
@MainActor
class CardSetRepository: CardSetRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func createCardSet(name: String) async throws -> CardSet {
        let cardSet = CardSet(name: name)
        modelContext.insert(cardSet)
        try modelContext.save()
        return cardSet
    }

    func deleteCardSet(_ cardSet: CardSet) async throws {
        modelContext.delete(cardSet)
        try modelContext.save()
    }

    func updateCardSetName(_ cardSet: CardSet, newName: String) async throws {
        cardSet.name = newName
        try modelContext.save()
    }

    func fetchCardSets() -> [CardSet] {
        let fetchDescriptor = FetchDescriptor<CardSet>(sortBy: [SortDescriptor(\.createdDate, order: .reverse)])
        do {
            return try modelContext.fetch(fetchDescriptor)
        } catch {
            print("Error fetching card sets: \(error)")
            return []
        }
    }
}


// MARK: - Repository Errors
enum CardSetRepositoryError: LocalizedError {
    case objectNotFound

    var errorDescription: String? {
        switch self {
        case .objectNotFound:
            return "The requested object could not be found."
        }
    }
}