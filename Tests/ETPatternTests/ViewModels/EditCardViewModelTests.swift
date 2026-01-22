import Testing
import Foundation
@testable import ETPatternModels
@testable import ETPatternServices
@testable import ETPatternServices

@Suite("EditCardViewModel Tests")
@MainActor
struct EditCardViewModelTests {
    
    @Test("Initial state for new card")
    func initialStateForNewCard() {
        let mockService = MockCardService()
        let mockCoordinator = MockBrowseCoordinator()
        let viewModel = EditCardViewModel(
            card: nil,
            deckName: "Test Deck",
            service: mockService,
            coordinator: mockCoordinator
        )
        
        #expect(viewModel.isNewCard == true)
        #expect(viewModel.title == "New Card")
        #expect(viewModel.frontText == "")
        #expect(viewModel.backText == "")
    }
    
    @Test("Initial state for existing card")
    func initialStateForExistingCard() {
        let mockService = MockCardService()
        let mockCoordinator = MockBrowseCoordinator()
        let card = CardDisplayModel(id: 123, front: "Front", back: "Back", cardName: "Path", groupName: "Group", groupId: 1)
        
        let viewModel = EditCardViewModel(
            card: card,
            deckName: "Test Deck",
            service: mockService,
            coordinator: mockCoordinator
        )
        
        #expect(viewModel.isNewCard == false)
        #expect(viewModel.title == "Edit Card")
        #expect(viewModel.frontText == "Front")
        #expect(viewModel.backText == "Back")
    }
    
    @Test("Validation fails if fields are empty")
    func validationFailsIfFieldsEmpty() async {
        let mockService = MockCardService()
        let mockCoordinator = MockBrowseCoordinator()
        let viewModel = EditCardViewModel(service: mockService, coordinator: mockCoordinator)
        
        viewModel.frontText = ""
        viewModel.backText = ""
        await viewModel.save()
        
        #expect(viewModel.errorMessage == "Both fields are required")
        #expect(mockService.addCardCalled == false)
        #expect(mockService.updateCardCalled == false)
    }
    
    @Test("Save new card successfully")
    func saveNewCardSuccess() async {
        let mockService = MockCardService()
        let mockCoordinator = MockBrowseCoordinator()
        let viewModel = EditCardViewModel(
            deckName: "Test Deck",
            service: mockService,
            coordinator: mockCoordinator
        )
        
        viewModel.frontText = "New Front"
        viewModel.backText = "New Back"
        await viewModel.save()
        
        #expect(mockService.addCardCalled == true)
        #expect(mockService.lastAddedDeckName == "Test Deck")
        #expect(mockService.lastAddedFront == "New Front")
        #expect(mockService.lastAddedBack == "New Back")
        #expect(mockCoordinator.dismissEditCalled == true)
    }
    
    @Test("Save existing card successfully")
    func saveExistingCardSuccess() async {
        let mockService = MockCardService()
        let mockCoordinator = MockBrowseCoordinator()
        let card = CardDisplayModel(id: 123, front: "Old", back: "Old", cardName: "", groupName: "", groupId: 0)
        
        let viewModel = EditCardViewModel(
            card: card,
            service: mockService,
            coordinator: mockCoordinator
        )
        
        viewModel.frontText = "Updated Front"
        viewModel.backText = "Updated Back"
        await viewModel.save()
        
        #expect(mockService.updateCardCalled == true)
        #expect(mockService.lastUpdatedID == 123)
        #expect(mockService.lastUpdatedFront == "Updated Front")
        #expect(mockService.lastUpdatedBack == "Updated Back")
        #expect(mockCoordinator.dismissEditCalled == true)
    }
}
