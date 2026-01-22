import Testing
import SwiftUI
import SwiftData
@testable import ETPatternModels
@testable import ETPatternServices
@testable import ETPatternServices

@MainActor
struct AutoPlayViewModelTests {
    
    func makeDependencies() -> (AutoPlayViewModel, MockStudyService, MockAutoPlayCoordinator, MockTTSService, ModelContainer) {
        let schema = Schema([CardSet.self, Card.self, StudySession.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext
        
        // Seed Data
        let cardSet = CardSet(name: "Test Deck")
        context.insert(cardSet)
        
        // Create session
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
        let mockTTS = MockTTSService()
        
        let vm = AutoPlayViewModel(
            cardSet: cardSet,
            modelContext: context,
            service: mockService,
            coordinator: mockCoordinator
        )
        vm.setTTSService(mockTTS)
        
        return (vm, mockService, mockCoordinator, mockTTS, container)
    }
    
    @Test("Initialization starts playback")
    func testInitialization() async {
        let (vm, _, _, _, _container) = makeDependencies()
        await vm.onAppear()
        
        #expect(vm.isPlaying == true)
        #expect(vm.currentCard != nil)
        
        await vm.onDisappear()
        _ = _container
    }
    
    @Test("Toggle playback pauses and resumes")
    func testTogglePlayback() async {
        let (vm, _, _, _, _container) = makeDependencies()
        await vm.onAppear()
        
        #expect(vm.isPlaying == true)
        
        vm.togglePlayback()
        #expect(vm.isPlaying == false)
        
        vm.togglePlayback()
        #expect(vm.isPlaying == true)
        
        await vm.onDisappear()
        _ = _container
    }
    
    @Test("Toggle Flip pauses playback and flips card")
    func testToggleFlip() async {
        let (vm, _, _, mockTTS, _container) = makeDependencies()
        await vm.onAppear()
        
        #expect(vm.isFlipped == false)
        #expect(vm.isPlaying == true)
        
        vm.toggleFlip()
        
        #expect(vm.isFlipped == true)
        #expect(vm.isPlaying == false) // Should stop auto-play on manual interaction
        #expect(mockTTS.stopCalled == true) // Should stop speaking
        
        // Flip back
        vm.toggleFlip()
        #expect(vm.isFlipped == false)
        
        await vm.onDisappear()
        _ = _container
    }
    
    @Test("Cycle Strategy changes strategy")
    func testCycleStrategy() async {
        let (vm, _, _, _, _container) = makeDependencies()
        
        let initial = vm.studyStrategy
        vm.cycleStrategy()
        
        #expect(vm.studyStrategy != initial)
        
        await vm.onDisappear()
        _ = _container
    }
    
    @Test("Manual logic stops TTS")
    func testManualInteractionStopsTTS() async {
        let (vm, _, _, mockTTS, _container) = makeDependencies()
        await vm.onAppear()
        
        vm.manualNext()
        #expect(mockTTS.stopCalled == true)
        #expect(vm.isPlaying == false)
        
        await vm.onDisappear()
        _ = _container
    }
    
    @Test("Dismiss calls coordinator and stops playback")
    func testDismiss() async {
        let (vm, _, coordinator, mockTTS, _container) = makeDependencies()
        vm.dismiss()
        
        #expect(coordinator.dismissCalled == true)
        #expect(mockTTS.stopCalled == true)
        
        await vm.onDisappear()
        _ = _container
    }
}
