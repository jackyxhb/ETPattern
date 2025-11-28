//
//  SettingsView.swift
//  ETPattern
//
//  Created by admin on 29/11/2025.
//

import SwiftUI
import AVFoundation

struct SettingsView: View {
    @StateObject private var ttsService = TTSService()
    @State private var selectedVoice: String

    private let voiceOptions = [
        "en-US": "American English (en-US)",
        "en-GB": "British English (en-GB)"
    ]

    init() {
        let currentVoice = UserDefaults.standard.string(forKey: "selectedVoice") ?? "en-US"
        _selectedVoice = State(initialValue: currentVoice)
    }

    var body: some View {
        Form {
            Section(header: Text("Text-to-Speech")) {
                Picker("Voice", selection: $selectedVoice) {
                    ForEach(voiceOptions.keys.sorted(), id: \.self) { voiceId in
                        Text(voiceOptions[voiceId] ?? voiceId)
                            .tag(voiceId)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedVoice) { newValue in
                    ttsService.setVoice(newValue)
                }

                Button("Test Voice") {
                    ttsService.speak("Hello! This is a test of the selected voice.")
                }
                .buttonStyle(.bordered)
            }

            Section(header: Text("About")) {
                Text("English Pattern Flashcards")
                    .font(.headline)
                Text("Version 1.0")
                    .foregroundColor(.secondary)
                Text("Learn English patterns with spaced repetition")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .navigationTitle("Settings")
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView()
        }
    }
}