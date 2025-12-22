//
//  CardSetRepository.swift
//  ETPattern
//
//  Created by AI Agent on 22/12/2025.
//

import CoreData
import Foundation

// Import project modules
import class ETPattern.CardSet

/// Repository protocol for CardSet data operations
protocol CardSetRepositoryProtocol {
    func createCardSet(name: String) async throws -> CardSet
    func deleteCardSet(_ cardSet: CardSet) async throws
    func updateCardSetName(_ cardSet: CardSet, newName: String) async throws
    func fetchCardSets() -> [CardSet]
    func saveContext() async throws
}

/// Core Data repository for CardSet operations
class CardSetRepository: CardSetRepositoryProtocol {
    private let viewContext: NSManagedObjectContext

    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }

    func createCardSet(name: String) async throws -> CardSet {
        let cardSet = CardSet(context: viewContext)
        cardSet.name = name
        cardSet.createdDate = Date()
        try await saveContext()
        return cardSet
    }

    func deleteCardSet(_ cardSet: CardSet) async throws {
        viewContext.delete(cardSet)
        try await saveContext()
    }

    func updateCardSetName(_ cardSet: CardSet, newName: String) async throws {
        cardSet.name = newName
        try await saveContext()
    }

    func fetchCardSets() -> [CardSet] {
        let request = CardSet.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CardSet.createdDate, ascending: false)]
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching card sets: \(error)")
            return []
        }
    }

    func saveContext() async throws {
        try viewContext.save()
    }
}