//
//  CardSetRepository.swift
//  ETPattern
//
//  Created by AI Agent on 22/12/2025.
//

import CoreData
import Foundation

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
    private let mainContext: NSManagedObjectContext
    private let backgroundContextManager: BackgroundContextManager

    init(viewContext: NSManagedObjectContext, backgroundContextManager: BackgroundContextManager) {
        self.mainContext = viewContext
        self.backgroundContextManager = backgroundContextManager
    }

    func createCardSet(name: String) async throws -> CardSet {
        let cardSetObjectID = try await backgroundContextManager.performBackgroundTask { context in
            let cardSet = CardSet(context: context)
            cardSet.name = name
            cardSet.createdDate = Date()
            return cardSet.objectID
        }

        // Fetch the created object on the main context
        guard let cardSet = mainContext.object(with: cardSetObjectID) as? CardSet else {
            throw CardSetRepositoryError.objectNotFound
        }
        return cardSet
    }

    func deleteCardSet(_ cardSet: CardSet) async throws {
        let objectID = cardSet.objectID
        try await backgroundContextManager.performBackgroundTask { context in
            guard let backgroundCardSet = context.object(with: objectID) as? CardSet else {
                throw CardSetRepositoryError.objectNotFound
            }
            context.delete(backgroundCardSet)
        }
    }

    func updateCardSetName(_ cardSet: CardSet, newName: String) async throws {
        let objectID = cardSet.objectID
        try await backgroundContextManager.performBackgroundTask { context in
            guard let backgroundCardSet = context.object(with: objectID) as? CardSet else {
                throw CardSetRepositoryError.objectNotFound
            }
            backgroundCardSet.name = newName
        }
    }

    func fetchCardSets() -> [CardSet] {
        let request = CardSet.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CardSet.createdDate, ascending: false)]
        do {
            return try mainContext.fetch(request)
        } catch {
            print("Error fetching card sets: \(error)")
            return []
        }
    }

    func saveContext() async throws {
        // This method is now deprecated since saves happen automatically in background tasks
        // Keeping for backward compatibility
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