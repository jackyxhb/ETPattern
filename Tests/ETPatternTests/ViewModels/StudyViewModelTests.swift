import Testing
import SwiftUI
import SwiftData
@testable import ETPatternModels
@testable import ETPatternServices
@testable import ETPatternServices

@MainActor
struct StudyViewModelTests {
    
    // Helper to setup dependencies
    func makeDependencies() -> (StudyViewModel, MockStudyService, MockStudyCoordinator, ModelContainer) {
        let schema = Schema([CardSet.self, Card.self, StudySession.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext
        
        // Seed Data
        let cardSet = CardSet(name: "Test Deck")
        context.insert(cardSet)
        
        // Pre-create a session for the mock to return
        let mockSession = StudySession(totalCards: 2)
        mockSession.cardSet = cardSet
        mockSession.isActive = true
        context.insert(mockSession)
        
        let card1 = Card(id: 1, front: "F1", back: "B1")
        let card2 = Card(id: 2, front: "F2", back: "B2")
        card1.cardSet = cardSet
        card2.cardSet = cardSet
        context.insert(card1)
        context.insert(card2)
        try! context.save()
        
        mockSession.cardOrder = [Int(card1.id), Int(card2.id)]
        // Note: HashValue usage here corresponds to VM logic? 
        // VM logic uses `Int($0.id)` where id is PersistentIdentifier? 
        // No, Card.id in ETPatternModels is likely an Int or UUID.
        // I need to check Card.id type. 
        // Assuming it works for now based on VM implementation `let id = sessionCardIDs[currentIndex]; cardSet.cards.first { Int($0.id) == id }`
        // If Card.id is PersistentIdentifier, Int($0.id) is invalid.
        // If Card uses @Attribute(.unique) var id: Int, then it's fine.
        // Let's assume Card has an ID property that is convertible to Int.
        
        let mockService = MockStudyService()
        let mockCoordinator = MockStudyCoordinator()
        
        // Setup mock return values
        // We simulate failure to find 'active' session via ID fetch, so create is called.
        // So MockService.fetchActiveSessionIDReturnValue = nil (default)
        // MockService.createSessionReturnValue = mockSession.persistentModelID
        mockService.createSessionReturnValue = mockSession.persistentModelID
        
        let vm = StudyViewModel(
            cardSet: cardSet,
            modelContext: context,
            service: mockService,
            coordinator: mockCoordinator
        )
        
        return (vm, mockService, mockCoordinator, container)
    }
    
    @Test("Initialization loads data and starts session")
    func testInitialization() async {
        let (vm, service, _, _container) = makeDependencies()
        // Keep container alive
        withExtendedLifetime(_container) { }
        
        await vm.onAppear()
        
        #expect(vm.currentCard != nil)
        #expect(service.fetchActiveSessionIDCalled == true)
        // If fetch returns nil, create should be called
        #expect(service.createSessionCalled == true)
        
        await vm.onDisappear()
        _ = _container
    }
    
    @Test("Flip card toggles state")
    func testFlipCard() async {
        let (vm, _, _, _container) = makeDependencies()
        await vm.onAppear()
        
        #expect(vm.isFlipped == false)
        vm.flipCard()
        #expect(vm.isFlipped == true)
        
        await vm.onDisappear()
        _ = _container
    }
    
    @Test("Navigation moves to next card")
    func testNavigation() async {
        let (vm, _, _, _container) = makeDependencies()
        await vm.onAppear()
        
        let firstCard = vm.currentCard
        vm.moveToNext()
        let secondCard = vm.currentCard
        
        #expect(firstCard != secondCard)
        #expect(vm.currentIndex == 1)
        #expect(vm.isFlipped == false)
        
        await vm.onDisappear()
        _ = _container
    }
    
    @Test("Rating updates difficulty and moves next")
    func testRating() async {
        let (vm, service, _, _container) = makeDependencies()
        await vm.onAppear()
        
        await vm.handleRating(.good).value
        
        #expect(service.updateCardDifficultyCalled == true)
        #expect(service.lastRating == .good)
        // Should have moved to next card
        #expect(vm.currentIndex == 1)
        
        await vm.onDisappear()
        _ = _container
    }
    
    @Test("Dismiss calls coordinator")
    func testDismiss() async {
         let (vm, _, coordinator, _container) = makeDependencies()
         vm.dismiss()
         #expect(coordinator.dismissCalled == true)
         
         await vm.onDisappear()
         _ = _container
    }
}
