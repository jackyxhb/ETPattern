//
//  CardSetService.swift
//  ETPattern
//
//  Created by admin on 28/01/2026.
//

import Foundation
import SwiftData

protocol CardSetServiceProtocol: Sendable {
    @MainActor func fetchCardSets() async throws -> [CardSet]
    @MainActor func createCardSet(name: String) async throws -> CardSet
    @MainActor func deleteCardSet(_ cardSet: CardSet) async throws
    @MainActor func renameCardSet(_ cardSet: CardSet, newName: String) async throws
}

@MainActor
final class CardSetService: CardSetServiceProtocol {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func fetchCardSets() async throws -> [CardSet] {
        // Fix: Use correct property 'createdDate' instead of 'createdAt'
        let descriptor = FetchDescriptor<CardSet>(sortBy: [SortDescriptor(\.createdDate, order: .reverse)])
        return try modelContext.fetch(descriptor)
    }
    
    func createCardSet(name: String) async throws -> CardSet {
        let newSet = CardSet(name: name)
        modelContext.insert(newSet)
        try modelContext.save()
        return newSet
    }
    
    func deleteCardSet(_ cardSet: CardSet) async throws {
        modelContext.delete(cardSet)
        try modelContext.save()
    }
    
    func renameCardSet(_ cardSet: CardSet, newName: String) async throws {
        cardSet.name = newName
        try modelContext.save()
    }
}
