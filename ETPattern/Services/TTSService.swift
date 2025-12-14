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
    private var currentVoice: String
    private var currentPercentage: Float  // Store as percentage (50-120)
    private var currentPitch: Float
    private var currentVolume: Float
    private var currentPause: TimeInterval
    private var completionHandler: (() -> Void)?
    private var isManuallyStopped = false
    private var lastError: AppError?

    @Published var isSpeaking = false
    @Published var errorMessage: String?

    override init() {
        self.currentVoice = UserDefaults.standard.string(forKey: "selectedVoice") ?? "en-US"
        // Load stored percentage, default to 100% if not set
        let storedPercentage = UserDefaults.standard.float(forKey: "ttsPercentage")
        self.currentPercentage = storedPercentage > 0 ? storedPercentage : Constants.TTS.defaultPercentage
        let storedPitch = UserDefaults.standard.float(forKey: "ttsPitch")
        self.currentPitch = storedPitch > 0 ? storedPitch : Constants.TTS.defaultPitch
        let storedVolume = UserDefaults.standard.float(forKey: "ttsVolume")
        self.currentVolume = storedVolume >= 0 ? storedVolume : Constants.TTS.defaultVolume
        let storedPause = UserDefaults.standard.double(forKey: "ttsPause")
        self.currentPause = storedPause >= 0 ? storedPause : Constants.TTS.defaultPause
        super.init()
        synthesizer.delegate = self
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

        // Check if the current voice is available
        guard let voice = AVSpeechSynthesisVoice(identifier: currentVoice),
              voice.language.starts(with: "en-") else {
            let error = AppError.ttsVoiceNotAvailable(voice: currentVoice)
            lastError = error
            errorMessage = error.localizedDescription
            print("TTS Error: \(error.localizedDescription)")
            return
        }

        completionHandler = completion

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
        isSpeaking = false
    }

    func setVoice(_ voiceIdentifier: String) {
        // Validate that the voice exists
        if AVSpeechSynthesisVoice(identifier: voiceIdentifier) != nil {
            currentVoice = voiceIdentifier
            UserDefaults.standard.set(voiceIdentifier, forKey: "selectedVoice")
            errorMessage = nil
            lastError = nil
        } else {
            let error = AppError.ttsVoiceNotAvailable(voice: voiceIdentifier)
            lastError = error
            errorMessage = error.localizedDescription
            print("TTS Error: \(error.localizedDescription)")
        }
    }

    func getCurrentVoice() -> String {
        return currentVoice
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
        guard !isManuallyStopped, let handler = completionHandler else {
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