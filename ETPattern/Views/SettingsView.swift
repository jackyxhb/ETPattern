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
    @State private var autoPlayOrderMode: String = UserDefaults.standard.string(forKey: "autoPlayOrderMode") ?? "sequential"
    @State private var ttsPercentage: Float = 0 // Will be set in onAppear

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

            Section(header: Text("Auto Play Mode")) {
                Picker("Card Order", selection: $autoPlayOrderMode) {
                    ForEach(orderOptions.keys.sorted(), id: \.self) { orderKey in
                        Text(orderOptions[orderKey] ?? orderKey)
                            .tag(orderKey)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: autoPlayOrderMode) { newValue in
                    UserDefaults.standard.set(newValue, forKey: "autoPlayOrderMode")
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

                VStack(alignment: .leading, spacing: 8) {
                    Text("Speech Speed: \(Int(ttsPercentage))%")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    GeometryReader { geometry in
                        Slider(value: $ttsPercentage, in: Constants.TTS.minPercentage...Constants.TTS.maxPercentage, step: 10) {
                            Text("Speech Speed")
                        } minimumValueLabel: {
                            Text("50%")
                                .font(.caption)
                        } maximumValueLabel: {
                            Text("120%")
                                .font(.caption)
                        }
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let sliderWidth = geometry.size.width
                                    let tapLocation = value.location.x
                                    let percentage = tapLocation / sliderWidth
                                    let newValue = Constants.TTS.minPercentage + (Constants.TTS.maxPercentage - Constants.TTS.minPercentage) * Float(percentage)
                                    let steppedValue = round(newValue / 10) * 10
                                    let clampedValue = min(max(steppedValue, Constants.TTS.minPercentage), Constants.TTS.maxPercentage)
                                    ttsPercentage = clampedValue
                                }
                        )
                        .onChange(of: ttsPercentage) { newValue in
                            ttsService.setRate(newValue)
                        }
                    }
                    .frame(height: 44) // Standard slider height
                }
                .padding(.vertical, 4)

                Button("Test Voice") {
                    UIImpactFeedbackGenerator.lightImpact()
                    ttsService.speak("Hello! This is a test of the selected voice and speed.")
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
            ttsPercentage = ttsService.getCurrentRate()
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