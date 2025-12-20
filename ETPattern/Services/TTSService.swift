//
//  TTSService.swift
//  ETPattern
//
//  Created by admin on 28/11/2025.
//

import Foundation
import AVFoundation
import Combine

class TTSService: NSObject, AVSpeechSynthesizerDelegate, ObservableObject, @unchecked Sendable {
    let objectWillChange = PassthroughSubject<Void, Never>()
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
    private var isManuallyStopped = false
    private var lastError: AppError?

    @Published var isSpeaking = false
    @Published var errorMessage: String?

    override init() {
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

        // Resolve initial voice preference to a concrete installed voice identifier.
        resolveVoicePreferenceAndPersistIfNeeded()
    }

    func speak(_ text: String, completion: (() -> Void)? = nil) {
        // Clear any previous error
        errorMessage = nil
        lastError = nil

        // Clear any previous state completely
        synthesizer.stopSpeaking(at: .immediate)
        completionHandler = nil
        isManuallyStopped = false

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
            let error = AppError.ttsVoiceNotAvailable(voice: voicePreference)
            lastError = error
            errorMessage = error.localizedDescription
            print("TTS Error: \(error.localizedDescription)")
            return
        }

        completionHandler = completion
        currentUtteranceSequence += 1
        completionSequence = currentUtteranceSequence

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = Constants.TTS.percentageToRate(currentPercentage)
        utterance.pitchMultiplier = currentPitch
        utterance.volume = currentVolume
        utterance.preUtteranceDelay = currentPause

        synthesizer.speak(utterance)
        isSpeaking = true
    }

    func stop() {
        isManuallyStopped = true
        synthesizer.stopSpeaking(at: .immediate)
        completionHandler = nil
        currentUtteranceSequence += 1  // Invalidate any pending completion handlers
        isSpeaking = false
    }

    /// Accepts either a concrete voice identifier (e.g. "com.apple.ttsbundle.Samantha-compact")
    /// or a language code (e.g. "en-US", "en-GB").
    func setVoice(_ voiceIdentifierOrLanguage: String) {
        voicePreference = voiceIdentifierOrLanguage
        resolveVoicePreferenceAndPersistIfNeeded()
    }

    func getCurrentVoice() -> String {
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
        let error = AppError.ttsVoiceNotAvailable(voice: voicePreference)
        lastError = error
        errorMessage = error.localizedDescription
        print("TTS Error: \(error.localizedDescription)")
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

    func setRate(_ rate: Float) {
        currentPercentage = max(Constants.TTS.minPercentage, min(Constants.TTS.maxPercentage, rate))
        UserDefaults.standard.set(currentPercentage, forKey: "ttsPercentage")
    }

    func getCurrentRate() -> Float {
        return currentPercentage
    }

    func setPitch(_ pitch: Float) {
        currentPitch = max(Constants.TTS.minPitch, min(Constants.TTS.maxPitch, pitch))
        UserDefaults.standard.set(currentPitch, forKey: "ttsPitch")
    }

    func getCurrentPitch() -> Float {
        return currentPitch
    }

    func setVolume(_ volume: Float) {
        currentVolume = max(Constants.TTS.minVolume, min(Constants.TTS.maxVolume, volume))
        UserDefaults.standard.set(currentVolume, forKey: "ttsVolume")
    }

    func getCurrentVolume() -> Float {
        return currentVolume
    }

    func setPause(_ pause: TimeInterval) {
        currentPause = max(Constants.TTS.minPause, min(Constants.TTS.maxPause, pause))
        UserDefaults.standard.set(currentPause, forKey: "ttsPause")
    }

    func getCurrentPause() -> TimeInterval {
        return currentPause
    }

    func getAvailableVoices() -> [AVSpeechSynthesisVoice] {
        return AVSpeechSynthesisVoice.speechVoices().filter { voice in
            voice.language.starts(with: "en-")
        }
    }

    // MARK: - AVSpeechSynthesizerDelegate
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        // Check state synchronously to prevent race conditions
        guard !isManuallyStopped, let handler = completionHandler, completionSequence == currentUtteranceSequence else {
            return
        }

        // Clear the handler before calling it to prevent double calls
        completionHandler = nil

        // Update speaking state
        isSpeaking = false

        // Call the completion handler
        handler()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
        completionHandler = nil
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        isSpeaking = true
    }
}