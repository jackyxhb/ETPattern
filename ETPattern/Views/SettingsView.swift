//
//  SettingsView.swift
//  ETPattern
//
//  Created by admin on 29/11/2025.
//

import SwiftUI
import AVFoundation

struct SettingsView: View {
    @Environment(\.theme) var theme
    @EnvironmentObject private var ttsService: TTSService
    @State private var selectedVoice: String = Constants.TTS.defaultVoice
    @State private var cardOrderMode: String = UserDefaults.standard.string(forKey: "cardOrderMode") ?? "random"
    @State private var autoPlayOrderMode: String = UserDefaults.standard.string(forKey: "autoPlayOrderMode") ?? "sequential"
    @State private var ttsPercentage: Float = 0 // Will be set in onAppear
    @State private var ttsPitch: Float = 0
    @State private var ttsVolume: Float = 0
    @State private var ttsPause: TimeInterval = 0

    private let voiceOptions = [
        "en-US": "American English (en-US)",
        "en-GB": "British English (en-GB)"
    ]

    private let orderOptions = [
        "random": "Random Order",
        "sequential": "Import Order"
    ]

    var body: some View {
        ZStack {
            theme.gradients.background
                .ignoresSafeArea()
            Form {
            Section(header: Text("Study Mode").foregroundColor(theme.colors.textPrimary)) {
                Picker(selection: $cardOrderMode) {
                    ForEach(orderOptions.keys.sorted(), id: \.self) { orderKey in
                        Text(orderOptions[orderKey] ?? orderKey)
                            .foregroundColor(theme.colors.textPrimary)
                            .tag(orderKey)
                    }
                } label: {
                    Text("Card Order")
                        .foregroundColor(theme.colors.textPrimary)
                }
                .pickerStyle(.menu)
                .onChange(of: cardOrderMode) { newValue in
                    UserDefaults.standard.set(newValue, forKey: "cardOrderMode")
                }
            }
            .listRowBackground(theme.colors.surfaceLight)

            Section(header: Text("Auto Play Mode").foregroundColor(theme.colors.textPrimary)) {
                Picker(selection: $autoPlayOrderMode) {
                    ForEach(orderOptions.keys.sorted(), id: \.self) { orderKey in
                        Text(orderOptions[orderKey] ?? orderKey)
                            .foregroundColor(theme.colors.textPrimary)
                            .tag(orderKey)
                    }
                } label: {
                    Text("Card Order")
                        .foregroundColor(theme.colors.textPrimary)
                }
                .pickerStyle(.menu)
                .onChange(of: autoPlayOrderMode) { newValue in
                    UserDefaults.standard.set(newValue, forKey: "autoPlayOrderMode")
                }
            }
            .listRowBackground(theme.colors.surfaceLight)

            Section(header: Text("Text-to-Speech").foregroundColor(theme.colors.textPrimary)) {
                Picker(selection: $selectedVoice) {
                    ForEach(voiceOptions.keys.sorted(), id: \.self) { voiceId in
                        Text(voiceOptions[voiceId] ?? voiceId)
                            .foregroundColor(theme.colors.textPrimary)
                            .tag(voiceId)
                    }
                } label: {
                    Text("Voice")
                        .foregroundColor(theme.colors.textPrimary)
                }
                .pickerStyle(.menu)
                .onChange(of: selectedVoice) { newValue in
                    ttsService.setVoice(newValue)
                }

                VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                    Text("Speech Speed: \(Int(ttsPercentage))%")
                        .font(theme.typography.subheadline)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    GeometryReader { geometry in
                        Slider(value: $ttsPercentage, in: Constants.TTS.minPercentage...Constants.TTS.maxPercentage, step: 10) {
                            Text("Speech Speed")
                                .foregroundColor(theme.colors.textPrimary)
                        } minimumValueLabel: {
                            Text("50%")
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colors.textSecondary)
                        } maximumValueLabel: {
                            Text("120%")
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colors.textSecondary)
                        }
                        .tint(theme.colors.highlight)
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
                    .frame(height: theme.metrics.sliderHeight) // Standard slider height
                }
                .padding(.vertical, theme.metrics.smallSpacing)
                .listRowBackground(theme.colors.surfaceLight)

                VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                    Text("Pitch: \(Int(ttsPitch * 100))%")
                        .font(theme.typography.subheadline)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Slider(value: $ttsPitch, in: Constants.TTS.minPitch...Constants.TTS.maxPitch, step: 0.1) {
                        Text("Pitch")
                            .foregroundColor(theme.colors.textPrimary)
                    } minimumValueLabel: {
                        Text("50%")
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textSecondary)
                    } maximumValueLabel: {
                        Text("200%")
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    .tint(theme.colors.highlight)
                    .onChange(of: ttsPitch) { newValue in
                        ttsService.setPitch(newValue)
                    }
                }
                .padding(.vertical, theme.metrics.smallSpacing)
                .listRowBackground(theme.colors.surfaceLight)

                VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                    Text("Volume: \(Int(ttsVolume * 100))%")
                        .font(theme.typography.subheadline)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Slider(value: $ttsVolume, in: Constants.TTS.minVolume...Constants.TTS.maxVolume, step: 0.1) {
                        Text("Volume")
                            .foregroundColor(theme.colors.textPrimary)
                    } minimumValueLabel: {
                        Text("0%")
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textSecondary)
                    } maximumValueLabel: {
                        Text("100%")
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    .tint(theme.colors.highlight)
                    .onChange(of: ttsVolume) { newValue in
                        ttsService.setVolume(newValue)
                    }
                }
                .padding(.vertical, theme.metrics.smallSpacing)
                .listRowBackground(theme.colors.surfaceLight)

                VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                    Text("Pause: \(String(format: "%.1f", ttsPause))s")
                        .font(theme.typography.subheadline)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Slider(value: $ttsPause, in: Constants.TTS.minPause...Constants.TTS.maxPause, step: 0.1) {
                        Text("Pause")
                            .foregroundColor(theme.colors.textPrimary)
                    } minimumValueLabel: {
                        Text("0s")
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textSecondary)
                    } maximumValueLabel: {
                        Text("2s")
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    .tint(theme.colors.highlight)
                    .onChange(of: ttsPause) { newValue in
                        ttsService.setPause(newValue)
                    }
                }
                .padding(.vertical, theme.metrics.smallSpacing)
                .listRowBackground(theme.colors.surfaceLight)

                Button("Test Voice") {
                    UIImpactFeedbackGenerator.lightImpact()
                    ttsService.speak("Hello! This is a test of the selected voice and speed.")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(theme.gradients.accent)
                .foregroundColor(theme.colors.textPrimary)
                .cornerRadius(theme.metrics.cornerRadius)
                .listRowBackground(theme.colors.surfaceLight)
            }
            .listRowBackground(theme.colors.surfaceLight)

            Section(header: Text("About").foregroundColor(theme.colors.textPrimary)) {
                Text("English Pattern Flashcards")
                    .font(theme.typography.headline)
                    .foregroundColor(theme.colors.textPrimary)
                Text("Version 1.0")
                    .foregroundColor(theme.colors.textSecondary)
                Text("Learn English patterns with spaced repetition")
                    .foregroundColor(theme.colors.textSecondary)
                    .font(theme.typography.caption)
            }
            .listRowBackground(theme.colors.surfaceLight)
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Settings")
        .onAppear {
            let stored = UserDefaults.standard.string(forKey: "selectedVoice") ?? Constants.TTS.defaultVoice
            selectedVoice = canonicalVoiceLanguage(from: stored)
            ttsPercentage = ttsService.getCurrentRate()
            ttsPitch = ttsService.getCurrentPitch()
            ttsVolume = ttsService.getCurrentVolume()
            ttsPause = ttsService.getCurrentPause()
        }
    }

    private func canonicalVoiceLanguage(from value: String) -> String {
        if voiceOptions.keys.contains(value) {
            return value
        }

        // If an older build stored a concrete voice identifier, map it back to a language.
        if let voice = AVSpeechSynthesisVoice(identifier: value), voiceOptions.keys.contains(voice.language) {
            return voice.language
        }

        return Constants.TTS.defaultVoice
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