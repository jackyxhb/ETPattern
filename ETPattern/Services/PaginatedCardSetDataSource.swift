//
//  PaginatedCardSetDataSource.swift
//  ETPattern
//
//  Created by admin on 22/12/2025.
//

import Foundation
import CoreData
@preconcurrency import Combine

protocol PaginatedCardSetDataSourceProtocol {
    var cardSets: [CardSet] { get }
    var isLoading: Bool { get }
    var hasMoreData: Bool { get }
    var error: AppError? { get }
    
    func loadInitialData() async
    func loadMoreData() async
    func refreshData() async
    func invalidateCache()
}

@MainActor
class PaginatedCardSetDataSource: ObservableObject, PaginatedCardSetDataSourceProtocol {
    // MARK: - Published Properties
    @Published private(set) var cardSets: [CardSet] = []
    @Published private(set) var isLoading = false
    @Published private(set) var hasMoreData = true
    @Published private(set) var error: AppError?
    
    // MARK: - Private Properties
    private let viewContext: NSManagedObjectContext
    private let pageSize: Int
    private var currentOffset = 0
    private var isLoadingMore = false
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(viewContext: NSManagedObjectContext, pageSize: Int = 20) {
        self.viewContext = viewContext
        self.pageSize = pageSize
        
        setupSubscriptions()
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
    
    // MARK: - Public Methods
    func loadInitialData() async {
        guard !isLoading else { return }
        
        await MainActor.run {
            isLoading = true
            error = nil
            currentOffset = 0
            cardSets = []
        }
        
        do {
            let newCardSets = try await fetchCardSets(offset: 0, limit: pageSize)
            await MainActor.run {
                cardSets = newCardSets
                currentOffset = newCardSets.count
                hasMoreData = newCardSets.count >= pageSize
                isLoading = false
            }
        } catch let appError as AppError {
            await MainActor.run {
                error = appError
                isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = AppError.coreDataSaveFailed(reason: error.localizedDescription)
                isLoading = false
            }
        }
    }
    
    func loadMoreData() async {
        guard !isLoading && !isLoadingMore && hasMoreData else { return }
        
        await MainActor.run {
            isLoadingMore = true
        }
        
        do {
            let newCardSets = try await fetchCardSets(offset: currentOffset, limit: pageSize)
            await MainActor.run {
                cardSets.append(contentsOf: newCardSets)
                currentOffset += newCardSets.count
                hasMoreData = newCardSets.count >= pageSize
                isLoadingMore = false
            }
        } catch let appError as AppError {
            await MainActor.run {
                error = appError
                isLoadingMore = false
            }
        } catch {
            await MainActor.run {
                self.error = AppError.coreDataSaveFailed(reason: error.localizedDescription)
                isLoadingMore = false
            }
        }
    }
    
    func refreshData() async {
        await loadInitialData()
    }
    
    func invalidateCache() {
        cardSets = []
        currentOffset = 0
        hasMoreData = true
        error = nil
    }
    
    // MARK: - Private Methods
    private func setupSubscriptions() {
        // Setup any future Combine subscriptions here
        // Currently no subscriptions, but infrastructure is ready
    }
    
    private func fetchCardSets(offset: Int, limit: Int) async throws -> [CardSet] {
        try await withCheckedThrowingContinuation { continuation in
            viewContext.perform {
                do {
                    let fetchRequest = NSFetchRequest<CardSet>(entityName: "CardSet")
                    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdDate", ascending: false)]
                    fetchRequest.fetchOffset = offset
                    fetchRequest.fetchLimit = limit
                    
                    let results = try self.viewContext.fetch(fetchRequest)
                    continuation.resume(returning: results)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}