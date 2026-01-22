import Foundation
import Combine
@testable import ETPatternServices

class MockTTSService: TTSService {
    var speakCalled = false
    var lastSpokenText: String?
    var stopCalled = false
    
    // Override init to avoid side effects if possible, but base init runs. 
    // We assume base init is safe.
    
    override func speak(_ text: String, completion: (() -> Void)? = nil) {
        speakCalled = true
        lastSpokenText = text
        // Simulate immediate completion or speaking state
        self.isSpeaking = true
        
        // Auto-finish after tiny delay to simulate successful speaking in tests without hanging
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 10_000_000)
            self.isSpeaking = false
            completion?()
        }
    }
    
    override func stop() {
        stopCalled = true
        self.isSpeaking = false
    }
}
