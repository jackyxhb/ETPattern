import Testing
import Foundation
import AVFoundation
@testable import ETPatternApp
import ETPatternCore
import ETPatternServices
import ETPatternServices

@Suite("Settings ViewModel Tests")
@MainActor
struct SettingsViewModelTests {
    
    @Test("Initialization loads values from UserDefaults and Service")
    func testInitialization() async throws {
        // Arrange
        let ttsService = TTSService.shared
        
        // Act
        let viewModel = SettingsViewModel(ttsService: ttsService)
        
        // Assert
        #expect(viewModel.ttsPercentage == ttsService.getCurrentRate())
        #expect(viewModel.ttsPitch == ttsService.getCurrentPitch())
        #expect(viewModel.ttsVolume == ttsService.getCurrentVolume())
        #expect(viewModel.ttsPause == Float(ttsService.getCurrentPause()))
    }
    
    @Test("Updating voice persists to UserDefaults and Service")
    func testUpdateVoice() async throws {
        // Arrange
        let ttsService = TTSService.shared
        let viewModel = SettingsViewModel(ttsService: ttsService)
        let testVoice = "en-GB"
        
        // Act
        viewModel.updateVoice(testVoice)
        
        // Assert
        #expect(UserDefaults.standard.string(forKey: "selectedVoice") == testVoice)
        // Note: TTSService internal state check might require exposure or mocks, 
        // but we verify the ViewModel property at least.
        #expect(viewModel.selectedVoice == testVoice)
    }
    
    @Test("Updating card order persists to UserDefaults")
    func testUpdateCardOrder() async throws {
        // Arrange
        let viewModel = SettingsViewModel(ttsService: .shared)
        let testOrder = "sequential"
        
        // Act
        viewModel.updateCardOrder(testOrder)
        
        // Assert
        #expect(UserDefaults.standard.string(forKey: "cardOrderMode") == testOrder)
        #expect(viewModel.cardOrderMode == testOrder)
    }
    
    @Test("Updating TTS rate updates service")
    func testUpdateRate() async throws {
        // Arrange
        let ttsService = TTSService.shared
        let viewModel = SettingsViewModel(ttsService: ttsService)
        let testRate: Float = 80.0
        
        // Act
        viewModel.updateRate(testRate)
        
        // Assert
        #expect(viewModel.ttsPercentage == testRate)
        #expect(ttsService.getCurrentRate() == testRate)
    }
    
    @Test("Updating TTS pause updates service")
    func testUpdatePause() async throws {
        // Arrange
         let ttsService = TTSService.shared
        let viewModel = SettingsViewModel(ttsService: ttsService)
        let testPause: Float = 1.5
        
        // Act
        viewModel.updatePause(testPause)
        
        // Assert
        #expect(viewModel.ttsPause == testPause)
        #expect(ttsService.getCurrentPause() == TimeInterval(testPause))
    }
}
