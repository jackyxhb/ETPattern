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
                studyModeSection
                ttsSection
                aboutSection
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

    private var studyModeSection: some View {
        Group {
            SharedSettingsPickerSection(
                header: "Study Mode",
                label: "Card Order",
                options: orderOptions,
                selection: $cardOrderMode,
                userDefaultsKey: "cardOrderMode"
            )

            SharedSettingsPickerSection(
                header: "Auto Play Mode",
                label: "Card Order",
                options: orderOptions,
                selection: $autoPlayOrderMode,
                userDefaultsKey: "autoPlayOrderMode"
            )
        }
    }

    private var ttsSection: some View {
        Section(header: Text("Text-to-Speech").foregroundColor(theme.colors.textPrimary)) {
            SharedSettingsPickerSection(
                header: "",
                label: "Voice",
                options: voiceOptions,
                selection: $selectedVoice,
                onChange: { newValue in
                    ttsService.setVoice(newValue)
                }
            )

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
                .frame(height: theme.metrics.sliderHeight)
            }
            .padding(.vertical, theme.metrics.smallSpacing)
            .listRowBackground(theme.colors.surfaceLight)

            SharedSettingsSliderSection(
                label: "Pitch",
                value: $ttsPitch,
                minValue: Constants.TTS.minPitch,
                maxValue: Constants.TTS.maxPitch,
                step: 0.1,
                minLabel: "50%",
                maxLabel: "200%",
                valueFormatter: { "\(Int($0 * 100))%" },
                onChange: { newValue in
                    ttsService.setPitch(newValue)
                }
            )

            SharedSettingsSliderSection(
                label: "Volume",
                value: $ttsVolume,
                minValue: Constants.TTS.minVolume,
                maxValue: Constants.TTS.maxVolume,
                step: 0.1,
                minLabel: "0%",
                maxLabel: "100%",
                valueFormatter: { "\(Int($0 * 100))%" },
                onChange: { newValue in
                    ttsService.setVolume(newValue)
                }
            )

            SharedSettingsSliderSection(
                label: "Pause",
                value: $ttsPause,
                minValue: Constants.TTS.minPause,
                maxValue: Constants.TTS.maxPause,
                step: 0.1,
                minLabel: "0s",
                maxLabel: "2s",
                valueFormatter: { String(format: "%.1f", $0) + "s" },
                onChange: { newValue in
                    ttsService.setPause(newValue)
                }
            )

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
    }

    private var aboutSection: some View {
        Section(header: Text("About").foregroundColor(theme.colors.textPrimary)) {
            Text("English Thought")
                .font(theme.typography.headline)
                .foregroundColor(theme.colors.textPrimary)
            Text("Version 1.6.0")
                .foregroundColor(theme.colors.textSecondary)
            Text("Learn English patterns with spaced repetition")
                .foregroundColor(theme.colors.textSecondary)
                .font(theme.typography.caption)
        }
        .listRowBackground(theme.colors.surfaceLight)
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