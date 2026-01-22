import Testing
import Foundation
import SwiftData
@testable import ETPatternApp
import ETPatternModels
import ETPatternServices
import ETPatternServices

@Suite("Import ViewModel Tests")
@MainActor
struct ImportViewModelTests {
    
    @Test("Initialization sets initial state")
    func testInitialization() async throws {
        let container = try ModelContainer(for: CardSet.self, Card.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let viewModel = ImportViewModel(modelContext: container.mainContext, coordinator: nil)
        
        #expect(viewModel.isShowingFilePicker == false)
        #expect(viewModel.isImporting == false)
        #expect(viewModel.importError == nil)
        #expect(viewModel.showErrorAlert == false)
    }
    
    @Test("Handle file selection failure sets error state")
    func testHandleFileSelectionFailure() async throws {
        let container = try ModelContainer(for: CardSet.self, Card.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let viewModel = ImportViewModel(modelContext: container.mainContext, coordinator: nil)
        
        let error = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        viewModel.handleFileSelection(.failure(error))
        
        #expect(viewModel.importError == "Failed to select file: Test error")
        #expect(viewModel.showErrorAlert == true)
        #expect(viewModel.isImporting == false)
    }
    
    @Test("Successful import triggers coordinator dismissal")
    func testSuccessfulImport() async throws {
        let container = try ModelContainer(for: CardSet.self, Card.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let mockCoordinator = MockBrowseCoordinator()
        let viewModel = ImportViewModel(modelContext: container.mainContext, coordinator: mockCoordinator)
        
        // Create a temporary CSV file
        let csvContent = "Front;;Back;;Tags\nHello;;World;;test\n"
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("TestDeck.csv")
        try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
        
        // Act
        viewModel.handleFileSelection(.success([fileURL]))
        
        // Assert
        #expect(viewModel.isImporting == false)
        #expect(viewModel.importError == nil)
        #expect(mockCoordinator.dismissImportCalled == true)
        
        // Check if data was actually saved
        let cardSets = try container.mainContext.fetch(FetchDescriptor<CardSet>())
        #expect(cardSets.count == 1)
        #expect(cardSets.first?.name == "TestDeck")
        #expect(cardSets.first?.cards.count == 1)
        #expect(cardSets.first?.cards.first?.front == "Hello")
        
        // Cleanup
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    @Test("Import with empty file sets error")
    func testImportEmptyFile() async throws {
        let container = try ModelContainer(for: CardSet.self, Card.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let viewModel = ImportViewModel(modelContext: container.mainContext, coordinator: nil)
        
        // Create an empty temporary CSV file (only header)
        let csvContent = "Front;;Back;;Tags\n"
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("EmptyDeck.csv")
        try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
        
        // Act
        viewModel.handleFileSelection(.success([fileURL]))
        
        // Assert
        #expect(viewModel.importError == "No valid cards found in the CSV file. Please check the format.")
        #expect(viewModel.showErrorAlert == true)
        
        // Cleanup
        try? FileManager.default.removeItem(at: fileURL)
    }
}
