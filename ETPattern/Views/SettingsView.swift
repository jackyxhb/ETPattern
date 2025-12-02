//
//  SettingsView.swift
//  ETPattern
//
//  Created by admin on 29/11/2025.
//

import SwiftUI
import AVFoundation

struct SettingsView: View {
    @EnvironmentObject private var ttsService: TTSService
    @State private var selectedVoice: String = UserDefaults.standard.string(forKey: "selectedVoice") ?? Constants.TTS.defaultVoice
    @State private var cardOrderMode: String = UserDefaults.standard.string(forKey: "cardOrderMode") ?? "random"

    private let voiceOptions = [
        "en-US": "American English (en-US)",
        "en-GB": "British English (en-GB)"
    ]

    private let orderOptions = [
        "random": "Random Order",
        "sequential": "Import Order"
    ]

    var body: some View {
        Form {
            Section(header: Text("Study Mode")) {
                Picker("Card Order", selection: $cardOrderMode) {
                    ForEach(orderOptions.keys.sorted(), id: \.self) { orderKey in
                        Text(orderOptions[orderKey] ?? orderKey)
                            .tag(orderKey)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: cardOrderMode) { newValue in
                    UserDefaults.standard.set(newValue, forKey: "cardOrderMode")
                }
            }

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
        .onAppear {
            selectedVoice = ttsService.getCurrentVoice()
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView()
                .environmentObject(TTSService())
        }
    }
}