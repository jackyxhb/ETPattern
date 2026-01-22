import Foundation
import Observation
import ETPatternModels
import ETPatternServices

@Observable @MainActor
public class EditCardViewModel {
    // MARK: - internal State
    public var frontText: String = ""
    public var backText: String = ""
    public var isLoading = false
    public var errorMessage: String?
    
    // MARK: - Properties
    private let cardID: Int32?
    private let deckName: String?
    private let service: CardServiceProtocol
    private weak var coordinator: BrowseCoordinator?
    
    public var isNewCard: Bool { cardID == nil }
    public var title: String { isNewCard ? "New Card" : "Edit Card" }
    
    public init(
        card: CardDisplayModel? = nil,
        deckName: String? = nil,
        service: CardServiceProtocol,
        coordinator: BrowseCoordinator?
    ) {
        self.cardID = card?.id
        self.deckName = deckName
        self.frontText = card?.front ?? ""
        self.backText = card?.back ?? ""
        self.service = service
        self.coordinator = coordinator
    }
    
    // MARK: - Actions
    
    public func save() async {
        guard !frontText.isEmpty && !backText.isEmpty else {
            errorMessage = "Both fields are required"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            if let id = cardID {
                try await service.updateCard(id: id, front: frontText, back: backText)
            } else if let deckName = deckName {
                let _ = try await service.addCard(to: deckName, front: frontText, back: backText)
            }
            coordinator?.dismissEdit()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    public func cancel() {
        coordinator?.dismissEdit()
    }
}
