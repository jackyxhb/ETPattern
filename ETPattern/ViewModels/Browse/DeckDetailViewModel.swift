import Foundation
import SwiftData
import ETPatternModels
import ETPatternServices
import ETPatternServices

@Observable @MainActor
class DeckDetailViewModel {
    // MARK: - internal State
    private(set) var sections: [DeckSection] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    
    // MARK: - Properties
    let deckName: String
    
    // MARK: - Dependencies
    let service: CardServiceProtocol
    private let coordinator: BrowseCoordinator? // Strong Ref
    
    init(cardSet: CardSet, service: CardServiceProtocol, coordinator: BrowseCoordinator?) {
        self.deckName = cardSet.name
        self.service = service
        self.coordinator = coordinator
    }
    
    // MARK: - Actions
    
    func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            self.sections = try await service.fetchDeckSections(for: deckName)
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func close() {
        coordinator?.dismiss()
    }
    
    func previewCard(_ card: CardDisplayModel) {
        coordinator?.presentPreview(for: card)
    }
    
    func dismissPreview() {
        coordinator?.dismissPreview()
    }
    
    func addCard() {
        coordinator?.presentEdit(for: .empty)
    }
    
    func editCard(_ card: CardDisplayModel) {
        coordinator?.presentEdit(for: card)
    }
}
