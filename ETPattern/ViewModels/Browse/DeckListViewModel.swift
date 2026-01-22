import SwiftUI
import SwiftData
import ETPatternModels
import ETPatternServices
import ETPatternCore

@Observable @MainActor
public final class DeckListViewModel {
    // MARK: - Properties
    public private(set) var cardSets: [CardSet] = []
    public private(set) var isLoading = false
    public private(set) var errorMessage: String?
    
    // UI State for renaming/creating
    public var showingCreateAlert = false
    public var newDeckName = ""
    
    private let service: CardServiceProtocol
    
    // MARK: - Initialization
    public init(service: CardServiceProtocol) {
        self.service = service
    }
    
    // MARK: - Public Methods
    public func onAppear() async {
        await loadCardSets()
    }
    
    public func loadCardSets() async {
        isLoading = true
        errorMessage = nil
        do {
            self.cardSets = try await service.fetchCardSets()
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    public func createDeck() {
        guard !newDeckName.isEmpty else { return }
        let name = newDeckName
        newDeckName = ""
        showingCreateAlert = false
        
        Task {
            isLoading = true
            do {
                _ = try await service.createCardSet(name: name)
                await loadCardSets()
            } catch {
                self.errorMessage = "Failed to create deck: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
    
    public func deleteSet(_ cardSet: CardSet) {
        Task {
            do {
                try await service.deleteCardSet(cardSet.persistentModelID)
                await loadCardSets() // Refresh
            } catch {
                self.errorMessage = "Failed to delete: \(error.localizedDescription)"
            }
        }
    }
}
