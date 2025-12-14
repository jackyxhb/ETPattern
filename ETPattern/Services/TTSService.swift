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
    private var completionHandler: (() -> Void)?
    private var isManuallyStopped = false

    override init() {
        self.currentVoice = UserDefaults.standard.string(forKey: "selectedVoice") ?? "en-US"
        // Load stored percentage, default to 100% if not set
        let storedPercentage = UserDefaults.standard.float(forKey: "ttsPercentage")
        self.currentPercentage = storedPercentage > 0 ? storedPercentage : Constants.TTS.defaultPercentage
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String, completion: (() -> Void)? = nil) {
        // Clear any previous state completely
        synthesizer.stopSpeaking(at: .immediate)
        completionHandler = nil
        isManuallyStopped = false

        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            // If text is empty, call completion immediately
            completion?()
            return
        }

        completionHandler = completion

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(identifier: currentVoice)
        utterance.rate = Constants.TTS.percentageToRate(currentPercentage)

        synthesizer.speak(utterance)
    }

    func stop() {
        isManuallyStopped = true
        synthesizer.stopSpeaking(at: .immediate)
        completionHandler = nil
    }

    func setVoice(_ voiceIdentifier: String) {
        currentVoice = voiceIdentifier
        UserDefaults.standard.set(voiceIdentifier, forKey: "selectedVoice")
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

        // Call the completion handler
        handler()
    }
}