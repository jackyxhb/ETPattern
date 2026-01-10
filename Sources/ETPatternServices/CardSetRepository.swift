//
//  CardSetRepository.swift
//  ETPattern
//
//  Created by AI Agent on 22/12/2025.
//

import Foundation
import SwiftData
import ETPatternModels

/// Repository protocol for CardSet data operations
@MainActor
public protocol CardSetRepositoryProtocol {
    func createCardSet(name: String) async throws -> CardSet
    func deleteCardSet(_ cardSet: CardSet) async throws
    func updateCardSetName(_ cardSet: CardSet, newName: String) async throws
    func fetchCardSets() -> [CardSet]
}

/// SwiftData repository for CardSet operations
@MainActor
public class CardSetRepository: CardSetRepositoryProtocol {
    private let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    public func createCardSet(name: String) async throws -> CardSet {
        let cardSet = CardSet(name: name)
        modelContext.insert(cardSet)
        try modelContext.save()
        return cardSet
    }

    public func deleteCardSet(_ cardSet: CardSet) async throws {
        modelContext.delete(cardSet)
        try modelContext.save()
    }

    public func updateCardSetName(_ cardSet: CardSet, newName: String) async throws {
        cardSet.name = newName
        try modelContext.save()
    }

    public func fetchCardSets() -> [CardSet] {
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
public enum CardSetRepositoryError: LocalizedError {
    case objectNotFound

    public var errorDescription: String? {
        switch self {
        case .objectNotFound:
            return "The requested object could not be found."
        }
    }
}