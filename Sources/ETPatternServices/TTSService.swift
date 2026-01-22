//
//  TTSService.swift
//  ETPattern
//
//  Created by admin on 28/11/2025.
//

import Foundation
import AVFoundation
@preconcurrency import Combine
import ETPatternCore

public enum TTSServiceError: LocalizedError {
    case ttsVoiceNotAvailable(voice: String)
    public var errorDescription: String? {
        switch self {
        case .ttsVoiceNotAvailable(let voice): return "TTS voice not available: \(voice)"
        }
    }
}

@MainActor
public class TTSService: NSObject, AVSpeechSynthesizerDelegate, @preconcurrency ObservableObject, @unchecked Sendable {
    // MARK: - Singleton
    public static let shared = TTSService()
    
    public let objectWillChange = PassthroughSubject<Void, Never>()
    private let synthesizer = AVSpeechSynthesizer()
    // Stores the user selection (either language like "en-US" or a concrete voice identifier).
    private var voicePreference: String
    // Stores the resolved voice identifier actually used for speaking.
    private var resolvedVoiceIdentifier: String?
    private var currentPercentage: Float  // Store as percentage (50-120)
    private var currentPitch: Float
    private var currentVolume: Float
    private var currentPause: TimeInterval
    private var completionHandler: (() -> Void)?
    private var completionSequence: Int = 0
    private var currentUtteranceSequence: Int = 0
    private var activeUtteranceID: ObjectIdentifier?
    private var lastError: TTSServiceError?
    
    // MARK: - Cancellable Storage
    private var cancellables = Set<AnyCancellable>()

    @Published public var isSpeaking = false
    @Published public var errorMessage: String?
    
    // Changed to public to allow subclassing in tests
    override public init() { 
        let storedPreference = UserDefaults.standard.string(forKey: "selectedVoice") ?? Constants.TTS.defaultVoice
        self.voicePreference = storedPreference
        self.resolvedVoiceIdentifier = nil
        
        // Load stored percentage, default to 100% if not set
        let storedPercentage = UserDefaults.standard.float(forKey: "ttsPercentage")
        self.currentPercentage = storedPercentage > 0 ? storedPercentage : Constants.TTS.defaultPercentage
        let storedPitch = UserDefaults.standard.float(forKey: "ttsPitch")
        self.currentPitch = storedPitch > 0 ? storedPitch : Constants.TTS.defaultPitch
        let storedVolume = UserDefaults.standard.object(forKey: "ttsVolume") as? Float
        self.currentVolume = storedVolume ?? Constants.TTS.defaultVolume
        let storedPause = UserDefaults.standard.double(forKey: "ttsPause")
        self.currentPause = storedPause >= 0 ? storedPause : Constants.TTS.defaultPause
        super.init()
        synthesizer.delegate = self

        // Configure Audio Session
        #if os(iOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)
        } catch {
            print("TTSService: Failed to configure audio session: \(error)")
        }
        #endif

        // Resolve initial voice preference to a concrete installed voice identifier.
        resolveVoicePreferenceAndPersistIfNeeded()
        
        setupSubscriptions()
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
    
    // MARK: - Private Setup Methods
    private func setupSubscriptions() {
        // Setup any future Combine subscriptions here
        // Currently no subscriptions, but infrastructure is ready
    }

    public func speak(_ text: String, completion: (() -> Void)? = nil) {
        // Clear any previous error
        errorMessage = nil
        lastError = nil

        // CRITICAL: Increment sequence FIRST to invalidate any pending didFinish callbacks
        // This prevents race conditions where old didFinish calls new handler
        currentUtteranceSequence += 1
        
        // Clear any previous state completely
        synthesizer.stopSpeaking(at: .immediate)
        completionHandler = nil
        activeUtteranceID = nil

        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            // If text is empty, call completion immediately
            completion?()
            return
        }

        // Ensure we have a valid installed voice identifier before speaking.
        if resolvedVoiceIdentifier == nil {
            resolveVoicePreferenceAndPersistIfNeeded()
        }
        guard let resolvedVoiceIdentifier,
              let voice = AVSpeechSynthesisVoice(identifier: resolvedVoiceIdentifier) else {
            let error = TTSServiceError.ttsVoiceNotAvailable(voice: voicePreference)
            lastError = error
            errorMessage = error.localizedDescription
            return
        }

        completionHandler = completion
        completionSequence = currentUtteranceSequence

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = Constants.TTS.percentageToRate(currentPercentage)
        utterance.pitchMultiplier = currentPitch
        utterance.volume = currentVolume
        utterance.preUtteranceDelay = currentPause
        
        self.activeUtteranceID = ObjectIdentifier(utterance)
        
        synthesizer.speak(utterance)
        isSpeaking = true
    }

    public func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        
        // CRITICAL: Call completion handler BEFORE clearing it
        // This ensures any awaiting continuation is resumed
        let handler = completionHandler
        completionHandler = nil
        activeUtteranceID = nil
        handler?()
        
        currentUtteranceSequence += 1  // Invalidate any pending completion handlers
        isSpeaking = false
    }

    /// Accepts either a concrete voice identifier (e.g. "com.apple.ttsbundle.Samantha-compact")
    /// or a language code (e.g. "en-US", "en-GB").
    public func setVoice(_ voiceIdentifierOrLanguage: String) {
        voicePreference = voiceIdentifierOrLanguage
        resolveVoicePreferenceAndPersistIfNeeded()
    }

    public func getCurrentVoice() -> String {
        // Return the persisted preference (language or identifier) so Settings stays stable.
        return voicePreference
    }

    private func resolveVoicePreferenceAndPersistIfNeeded() {
        errorMessage = nil
        lastError = nil

        // 1) If preference matches an installed identifier, use it directly.
        if let direct = AVSpeechSynthesisVoice(identifier: voicePreference) {
            resolvedVoiceIdentifier = direct.identifier
            UserDefaults.standard.set(voicePreference, forKey: "selectedVoice")
            return
        }

        // 2) If preference looks like a language code (en-XX), pick the best installed voice for that language.
        if voicePreference.hasPrefix("en-") {
            if let best = bestVoiceIdentifier(forLanguage: voicePreference) {
                resolvedVoiceIdentifier = best
                UserDefaults.standard.set(voicePreference, forKey: "selectedVoice")
                return
            }
        }

        // 3) Fall back to any English voice on the device.
        if let fallback = bestVoiceIdentifier(forLanguagePrefix: "en-") {
            resolvedVoiceIdentifier = fallback
            // Persist a stable preference if the previous one was invalid.
            voicePreference = Constants.TTS.defaultVoice
            UserDefaults.standard.set(voicePreference, forKey: "selectedVoice")
            return
        }

        // 4) Last resort (should be rare). Keep nil identifier and surface an error.
        resolvedVoiceIdentifier = nil
        let error = TTSServiceError.ttsVoiceNotAvailable(voice: voicePreference)
        lastError = error
        errorMessage = error.localizedDescription
    }

    private func bestVoiceIdentifier(forLanguage language: String) -> String? {
        let candidates = AVSpeechSynthesisVoice.speechVoices().filter { $0.language == language }
        return pickBestIdentifier(from: candidates)
    }

    private func bestVoiceIdentifier(forLanguagePrefix prefix: String) -> String? {
        let candidates = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.hasPrefix(prefix) }
        return pickBestIdentifier(from: candidates)
    }

    private func pickBestIdentifier(from voices: [AVSpeechSynthesisVoice]) -> String? {
        guard !voices.isEmpty else { return nil }
        // Prefer enhanced quality voices when available.
        let enhanced = voices.filter { $0.quality == .enhanced }
        if let first = enhanced.first { return first.identifier }
        return voices.first?.identifier
    }

    public func setRate(_ rate: Float) {
        currentPercentage = max(Constants.TTS.minPercentage, min(Constants.TTS.maxPercentage, rate))
        UserDefaults.standard.set(currentPercentage, forKey: "ttsPercentage")
    }

    public func getCurrentRate() -> Float {
        return currentPercentage
    }

    public func setPitch(_ pitch: Float) {
        currentPitch = max(Constants.TTS.minPitch, min(Constants.TTS.maxPitch, pitch))
        UserDefaults.standard.set(currentPitch, forKey: "ttsPitch")
    }

    public func getCurrentPitch() -> Float {
        return currentPitch
    }

    public func setVolume(_ volume: Float) {
        currentVolume = max(Constants.TTS.minVolume, min(Constants.TTS.maxVolume, volume))
        UserDefaults.standard.set(currentVolume, forKey: "ttsVolume")
    }

    public func getCurrentVolume() -> Float {
        return currentVolume
    }

    public func setPause(_ pause: TimeInterval) {
        currentPause = max(Constants.TTS.minPause, min(Constants.TTS.maxPause, pause))
        UserDefaults.standard.set(currentPause, forKey: "ttsPause")
    }

    public func getCurrentPause() -> TimeInterval {
        return currentPause
    }

    public func getAvailableVoices() -> [AVSpeechSynthesisVoice] {
        return AVSpeechSynthesisVoice.speechVoices().filter { voice in
            voice.language.starts(with: "en-")
        }
    }

    // MARK: - AVSpeechSynthesizerDelegate
    public nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let utteranceID = ObjectIdentifier(utterance)
        Task { @MainActor in
            // Check utterance ID and sequence to prevent stale completions
            guard utteranceID == self.activeUtteranceID,
                  let handler = self.completionHandler, 
                  self.completionSequence == self.currentUtteranceSequence else {
                return
            }
            
            // Clear state before calling handler
            self.completionHandler = nil
            self.activeUtteranceID = nil
            self.isSpeaking = false
            
            // Call the completion handler
            handler()
        }
    }

    public nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        let utteranceID = ObjectIdentifier(utterance)
        Task { @MainActor in
            // Check utterance ID and sequence to prevent calling wrong handler
            guard utteranceID == self.activeUtteranceID,
                  let handler = self.completionHandler, 
                  self.completionSequence == self.currentUtteranceSequence else {
                return
            }
            
            // Clear state before calling handler
            self.completionHandler = nil
            self.activeUtteranceID = nil
            self.isSpeaking = false
            
            // Call the completion handler
            handler()
        }
    }

    public nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = true
        }
    }
}