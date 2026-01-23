import Foundation
import SwiftData
@preconcurrency import Combine

@MainActor
protocol PaginatedCardSetDataSourceProtocol {
    var cardSets: [CardSet] { get }
    var isLoading: Bool { get }
    var hasMoreData: Bool { get }
    var error: DataSourceError? { get }
    
    func loadInitialData() async
    func loadMoreData() async
    func refreshData() async
    func invalidateCache()
}

enum DataSourceError: LocalizedError {
    case fetchFailed(reason: String)
    var errorDescription: String? {
        switch self {
        case .fetchFailed(let reason): return "Fetch failed: \(reason)"
        }
    }
}

@MainActor
class PaginatedCardSetDataSource: ObservableObject, PaginatedCardSetDataSourceProtocol {
    // MARK: - Published Properties
    @Published private(set) var cardSets: [CardSet] = []
    @Published private(set) var isLoading = false
    @Published private(set) var hasMoreData = true
    @Published private(set) var error: DataSourceError?
    
    // MARK: - Private Properties
    private let modelContext: ModelContext
    private let pageSize: Int
    private var currentOffset = 0
    private var isLoadingMore = false
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(modelContext: ModelContext, pageSize: Int = 20) {
        self.modelContext = modelContext
        self.pageSize = pageSize
        
        setupSubscriptions()
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
    
    // MARK: - Public Methods
    func loadInitialData() async {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        currentOffset = 0
        cardSets = []
        
        do {
            let newCardSets = try fetchCardSets(offset: 0, limit: pageSize)
            cardSets = newCardSets
            currentOffset = newCardSets.count
            hasMoreData = newCardSets.count >= pageSize
            isLoading = false
        } catch {
            self.error = .fetchFailed(reason: error.localizedDescription)
            isLoading = false
        }
    }
    
    func loadMoreData() async {
        guard !isLoading && !isLoadingMore && hasMoreData else { return }
        
        isLoadingMore = true
        
        do {
            let newCardSets = try fetchCardSets(offset: currentOffset, limit: pageSize)
            cardSets.append(contentsOf: newCardSets)
            currentOffset += newCardSets.count
            hasMoreData = newCardSets.count >= pageSize
            isLoadingMore = false
        } catch {
            self.error = .fetchFailed(reason: error.localizedDescription)
            isLoadingMore = false
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
    }
    
    private func fetchCardSets(offset: Int, limit: Int) throws -> [CardSet] {
        var fetchDescriptor = FetchDescriptor<CardSet>(
            sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
        )
        fetchDescriptor.fetchOffset = offset
        fetchDescriptor.fetchLimit = limit
        
        return try modelContext.fetch(fetchDescriptor)
    }
}