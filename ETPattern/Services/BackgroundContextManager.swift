//
//  BackgroundContextManager.swift
//  ETPattern
//
//  Created by AI Agent on 22/12/2025.
//

import CoreData
import Foundation

/// Manager for background Core Data contexts to ensure thread safety
class BackgroundContextManager {
    private let persistentContainer: NSPersistentContainer

    init(persistentContainer: NSPersistentContainer) {
        self.persistentContainer = persistentContainer
    }

    /// Creates a new background context configured for background operations
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        return context
    }

    /// Performs a background operation with automatic error handling and context saving
    func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        let context = newBackgroundContext()

        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let result = try block(context)
                    if context.hasChanges {
                        try context.save()
                    }
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Performs a background operation that returns Void
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) throws -> Void) async throws {
        let context = newBackgroundContext()

        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    try block(context)
                    if context.hasChanges {
                        try context.save()
                    }
                    continuation.resume(returning: ())
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}