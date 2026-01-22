import SwiftUI
import AVFoundation
import ETPatternCore
import ETPatternServices

@Observable @MainActor
public class SettingsViewModel {
    public var selectedVoice: String
    public var cardOrderMode: String
    public var autoPlayOrderMode: String
    public var ttsPercentage: Float
    public var ttsPitch: Float
    public var ttsVolume: Float
    public var ttsPause: Float
    
    public var currentTheme: AppTheme {
        get { ThemeManager.shared.currentTheme }
        set { ThemeManager.shared.currentTheme = newValue }
    }
    
    public let voiceOptions = [
        "en-US": NSLocalizedString("american_english", comment: "American English voice option"),
        "en-GB": NSLocalizedString("british_english", comment: "British English voice option")
    ]
    
    public let orderOptions = [
        "random": NSLocalizedString("random_order", comment: "Random card order option"),
        "sequential": NSLocalizedString("import_order", comment: "Sequential/Import card order option")
    ]
    
    private let ttsService: TTSService
    
    public init(ttsService: TTSService) {
        self.ttsService = ttsService
        
        // Load initial state
        let storedVoice = UserDefaults.standard.string(forKey: "selectedVoice") ?? Constants.TTS.defaultVoice
        self.selectedVoice = canonicalVoiceLanguage(from: storedVoice, options: voiceOptions)
        
        self.cardOrderMode = UserDefaults.standard.string(forKey: "cardOrderMode") ?? "random"
        self.autoPlayOrderMode = UserDefaults.standard.string(forKey: "autoPlayOrderMode") ?? "random"
        
        self.ttsPercentage = ttsService.getCurrentRate()
        self.ttsPitch = ttsService.getCurrentPitch()
        self.ttsVolume = ttsService.getCurrentVolume()
        self.ttsPause = Float(ttsService.getCurrentPause())
    }
    
    public func updateVoice(_ newValue: String) {
        selectedVoice = newValue
        UserDefaults.standard.set(newValue, forKey: "selectedVoice")
        ttsService.setVoice(newValue)
    }
    
    public func updateCardOrder(_ newValue: String) {
        cardOrderMode = newValue
        UserDefaults.standard.set(newValue, forKey: "cardOrderMode")
    }
    
    public func updateAutoPlayOrder(_ newValue: String) {
        autoPlayOrderMode = newValue
        UserDefaults.standard.set(newValue, forKey: "autoPlayOrderMode")
    }
    
    public func updateRate(_ newValue: Float) {
        ttsPercentage = newValue
        ttsService.setRate(newValue)
    }
    
    public func updatePitch(_ newValue: Float) {
        ttsPitch = newValue
        ttsService.setPitch(newValue)
    }
    
    public func updateVolume(_ newValue: Float) {
        ttsVolume = newValue
        ttsService.setVolume(newValue)
    }
    
    public func updatePause(_ newValue: Float) {
        ttsPause = newValue
        ttsService.setPause(TimeInterval(newValue))
    }
    
    public func testVoice() {
        #if os(iOS)
        UIImpactFeedbackGenerator.lightImpact()
        #else
        // macOS stub for haptics is already in Extensions.swift
        UIImpactFeedbackGenerator.lightImpact()
        #endif
        ttsService.speak("Hello! This is a test of the selected voice and speed.")
    }
    
    public var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "Version \(version) (\(build))"
    }
}

private func canonicalVoiceLanguage(from value: String, options: [String: String]) -> String {
    if options.keys.contains(value) {
        return value
    }
    if let voice = AVSpeechSynthesisVoice(identifier: value), options.keys.contains(voice.language) {
        return voice.language
    }
    return Constants.TTS.defaultVoice
}
