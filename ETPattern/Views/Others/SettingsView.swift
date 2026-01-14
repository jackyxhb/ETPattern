//
//  SettingsView.swift
//  ETPattern
//
//  Created by admin on 29/11/2025.
//

import SwiftUI
import AVFoundation
import ETPatternServices
import ETPatternCore

struct SettingsView: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var ttsService: TTSService
    @State private var selectedVoice: String = Constants.TTS.defaultVoice
    @State private var cardOrderMode: String = UserDefaults.standard.string(forKey: "cardOrderMode") ?? "random"
    @State private var autoPlayOrderMode: String = UserDefaults.standard.string(forKey: "autoPlayOrderMode") ?? "sequential"
    @State private var ttsPercentage: Float = 0 // Will be set in onAppear
    @State private var ttsPitch: Float = 0
    @State private var ttsVolume: Float = 0
    @State private var ttsPause: TimeInterval = 0

    private let voiceOptions = [
        "en-US": NSLocalizedString("american_english", comment: "American English voice option"),
        "en-GB": NSLocalizedString("british_english", comment: "British English voice option")
    ]

    private let orderOptions = [
        "random": NSLocalizedString("random_order", comment: "Random card order option"),
        "sequential": NSLocalizedString("import_order", comment: "Sequential/Import card order option")
    ]

    var body: some View {
        ZStack {
            theme.gradients.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom header for sheet presentation
                HStack {
                    Text(NSLocalizedString("settings", comment: "Settings screen title"))
                        .font(.headline)
                        .foregroundColor(theme.colors.textPrimary)
                        .dynamicTypeSize(.large ... .accessibility5)
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(theme.colors.textSecondary)
                            .font(.title2)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .themedGlassBackground()
                
                Form {
                    studyModeSection
                    appearanceSection
                    ttsSection
                    aboutSection
                }
                .scrollContentBackground(.hidden)
            }
        }
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
                header: NSLocalizedString("study_mode", comment: "Study mode section header"),
                label: NSLocalizedString("card_order", comment: "Card order label"),
                options: orderOptions,
                selection: $cardOrderMode,
                userDefaultsKey: "cardOrderMode"
            )

            SharedSettingsPickerSection(
                header: NSLocalizedString("auto_play_mode", comment: "Auto play mode section header"),
                label: NSLocalizedString("card_order", comment: "Card order label"),
                options: orderOptions,
                selection: $autoPlayOrderMode,
                userDefaultsKey: "autoPlayOrderMode"
            )
        }
    }

    private var appearanceSection: some View {
        Section(header: Text(NSLocalizedString("appearance", comment: "Appearance section header")).foregroundColor(theme.colors.textPrimary).dynamicTypeSize(.large ... .accessibility5)) {
            SharedSettingsPickerSection(
                header: "",
                label: NSLocalizedString("theme", comment: "Theme selection label"),
                options: Dictionary(uniqueKeysWithValues: AppTheme.allCases.map { ($0.rawValue, $0.displayName) }),
                selection: Binding(
                    get: { ThemeManager.shared.currentTheme.rawValue },
                    set: { newValue in
                        if let theme = AppTheme(rawValue: newValue) {
                            ThemeManager.shared.currentTheme = theme
                        }
                    }
                ),
                onChange: { _ in }
            )
        }
        .listRowBackground(theme.colors.surfaceLight)
    }

    private var ttsSection: some View {
        Section(header: Text(NSLocalizedString("text_to_speech", comment: "Text-to-speech section header")).foregroundColor(theme.colors.textPrimary).dynamicTypeSize(.large ... .accessibility5)) {
            SharedSettingsPickerSection(
                header: "",
                label: NSLocalizedString("voice", comment: "Voice selection label"),
                options: voiceOptions,
                selection: $selectedVoice,
                onChange: { newValue in
                    ttsService.setVoice(newValue)
                }
            )

            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                Text(String(format: NSLocalizedString("speech_speed_value", comment: "Speech speed display with percentage"), Int(ttsPercentage)))
                    .font(theme.metrics.subheadline)
                    .foregroundColor(theme.colors.textPrimary)
                    .dynamicTypeSize(.large ... .accessibility5)

                GeometryReader { geometry in
                    Slider(value: $ttsPercentage, in: Constants.TTS.minPercentage...Constants.TTS.maxPercentage, step: 10) {
                        Text(NSLocalizedString("speech_speed", comment: "Speech speed slider label"))
                            .foregroundColor(theme.colors.textPrimary)
                            .dynamicTypeSize(.large ... .accessibility5)
                    } minimumValueLabel: {
                        Text("50%")
                            .font(theme.metrics.caption)
                            .foregroundColor(theme.colors.textSecondary)
                            .dynamicTypeSize(.large ... .accessibility5)
                    } maximumValueLabel: {
                        Text("120%")
                            .font(theme.metrics.caption)
                            .foregroundColor(theme.colors.textSecondary)
                            .dynamicTypeSize(.large ... .accessibility5)
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
                    .onChange(of: ttsPercentage) { _, newValue in
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
        Section(header: Text("About").foregroundColor(theme.colors.textPrimary).dynamicTypeSize(.large ... .accessibility5)) {
            Text("English Thought")
                .font(theme.metrics.headline)
                .foregroundColor(theme.colors.textPrimary)
                .dynamicTypeSize(.large ... .accessibility5)
            Text(appVersion)
                .foregroundColor(theme.colors.textSecondary)
                .dynamicTypeSize(.large ... .accessibility5)
            Text("Learn English patterns with spaced repetition")
                .foregroundColor(theme.colors.textSecondary)
                .font(theme.metrics.caption)
                .dynamicTypeSize(.large ... .accessibility5)
        }
        .listRowBackground(theme.colors.surfaceLight)
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "Version \(version) (\(build))"
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

#Preview {
    NavigationView {
        SettingsView()
            .environmentObject(TTSService.shared)
    }
}