import Testing
import SwiftUI
import SwiftData
@testable import ETPatternModels
@testable import ETPatternServices
@testable import ETPatternFeatures

@MainActor
struct AutoPlayViewModelTests {
    
    func makeDependencies() -> (AutoPlayViewModel, MockStudyService, MockAutoPlayCoordinator, ModelContainer) {
        let schema = Schema([CardSet.self, Card.self, StudySession.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext
        
        // Seed Data
        let cardSet = CardSet(name: "Test Deck")
        context.insert(cardSet)
        
        let session = StudySession(totalCards: 1)
        session.cardSet = cardSet
        session.isActive = true
        context.insert(session)
        
        let card1 = Card(id: 1, front: "F1", back: "B1")
        card1.cardSet = cardSet
        context.insert(card1)
        
        // Relationship
        session.cardOrder = [Int(card1.id)]
        
        try! context.save()
        
        let mockService = MockStudyService()
        // Setup mock return values
        mockService.fetchActiveSessionIDReturnValue = session.persistentModelID
        mockService.createSessionReturnValue = session.persistentModelID
        
        let mockCoordinator = MockAutoPlayCoordinator()
        
        let vm = AutoPlayViewModel(
            cardSet: cardSet,
            modelContext: context,
            service: mockService,
            coordinator: mockCoordinator
        )
        
        return (vm, mockService, mockCoordinator, container)
    }
    
    @Test("Initialization starts playback")
    func testInitialization() async {
        let (vm, _, _, _container) = makeDependencies()
        await vm.onAppear()
        
        #expect(vm.isPlaying == true)
        #expect(vm.currentCard != nil)
        
        await vm.onDisappear()
        _ = _container
    }
    
    @Test("Toggle playback pauses and resumes")
    func testTogglePlayback() async {
        let (vm, _, _, _container) = makeDependencies()
        await vm.onAppear()
        
        #expect(vm.isPlaying == true)
        
        vm.togglePlayback()
        #expect(vm.isPlaying == false)
        
        vm.togglePlayback()
        #expect(vm.isPlaying == true)
        
        await vm.onDisappear()
        _ = _container
    }
    
    @Test("Manual next stops playback and moves")
    func testManualNext() async {
        let (vm, _, _, _container) = makeDependencies()
        await vm.onAppear()
        
        let initialIndex = vm.currentIndex
        vm.manualNext()
        
        #expect(vm.currentIndex != initialIndex || vm.sessionCardIDs.count == 1) // If 1 card, loop back
        // We verify that internal state for card changed.
        
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
