//
//  SettingsView.swift
//  ETPattern
//
//  Created by admin on 29/11/2025.
//

import SwiftUI
import AVFoundation

struct SettingsView: View {
    @Environment(AppCoordinator.self) var coordinator
    @Environment(\.theme) var theme
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var ttsService: TTSService
    @State private var selectedVoice: String = Constants.TTS.defaultVoice
    @State private var cardOrderMode: String = UserDefaults.standard.string(forKey: "cardOrderMode") ?? "random"
    @State private var autoPlayOrderMode: String = UserDefaults.standard.string(forKey: "autoPlayOrderMode") ?? "random"
    @State private var ttsPercentage: Float = 0 // Will be set in onAppear
    @State private var ttsPitch: Float = 0
    @State private var ttsVolume: Float = 0
    @State private var ttsPause: TimeInterval = 0
    
    @ObservedObject private var syncManager = CloudSyncManager.shared

    private let voiceOptions = [
        "en-US": NSLocalizedString("american_english", comment: "American English voice option"),
        "en-GB": NSLocalizedString("british_english", comment: "British English voice option")
    ]

    private let orderOptionsKeys = ["random", "sequential"]
    private let orderOptionsDict = [
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
                
                ScrollView {
                    LazyVStack(spacing: 24) {
                        generalSection
                        appearanceSection
                        ttsSection
                        syncSection
                        aboutSection
                    }
                    .padding(.vertical)
                }
            }
        }
        .preferredColorScheme(themeManager.colorScheme)
        .onAppear {
            // ... (keep same onAppear logic)
            let stored = UserDefaults.standard.string(forKey: "selectedVoice") ?? Constants.TTS.defaultVoice
            selectedVoice = canonicalVoiceLanguage(from: stored)
            ttsPercentage = ttsService.getCurrentRate()
            ttsPitch = ttsService.getCurrentPitch()
            ttsVolume = ttsService.getCurrentVolume()
            ttsPause = ttsService.getCurrentPause()
        }
    }

    // MARK: - Sections

    private var generalSection: some View {
        LiquidSettingsSection(title: "General") {
            // Moved from studyModeSection
            LiquidPickerRow(
                icon: "arrow.triangle.2.circlepath",
                color: .teal,
                title: NSLocalizedString("study_mode", comment: "Study mode label"),
                options: orderOptionsKeys,
                selection: $cardOrderMode,
                optionsDict: orderOptionsDict
            ) { newValue in
                UserDefaults.standard.set(newValue, forKey: "cardOrderMode")
            }
            
            Divider().padding(.leading, 64)

            LiquidPickerRow(
                icon: "play.circle",
                color: .green,
                title: NSLocalizedString("auto_play_mode", comment: "Auto play mode section header"),
                options: orderOptionsKeys,
                selection: $autoPlayOrderMode,
                optionsDict: orderOptionsDict
            ) { newValue in
                UserDefaults.standard.set(newValue, forKey: "autoPlayOrderMode")
            }
            
            Divider().padding(.leading, 64)
            
            LiquidSliderRow(
                icon: "target",
                color: .orange,
                title: "Daily Goal",
                value: Binding(
                    get: { Float(StatsService.shared.dailyGoal) },
                    set: { StatsService.shared.dailyGoal = Int($0) }
                ),
                range: 10...200,
                step: 10,
                formatter: { "\(Int($0)) cards" },
                onChange: { _ in }
            )
            
            Divider().padding(.leading, 64)
            
            LiquidSettingsButton(
                icon: "chart.bar.fill",
                color: .blue,
                title: "Usage Statistics"
            ) {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    coordinator.presentFullScreen(.sessionStats)
                }
            }
        }
    }

    private var syncSection: some View {
        LiquidSettingsSection(title: "Cloud Sync") {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sync Status")
                        .font(.headline)
                        .foregroundStyle(theme.colors.textPrimary)
                    
                    if syncManager.isSyncing {
                        Text("Syncing...")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    } else if let error = syncManager.syncError {
                        Text("Error: \(error.localizedDescription)")
                            .font(.caption)
                            .foregroundStyle(.red)
                    } else if let date = syncManager.lastSyncDate {
                        Text("Last synced: \(date.formattedDate())")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Waiting for sync...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(syncManager.statusLog)
                            .font(.caption2)
                            .foregroundStyle(.gray)
                    }
                }
                
                Spacer()
                
                if syncManager.isSyncing {
                    ProgressView()
                } else {
                    Image(systemName: "icloud.and.arrow.down")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
            }
            .padding()
            .liquidGlass()
        }
    }



    private var appearanceSection: some View {
        LiquidSettingsSection(title: NSLocalizedString("appearance", comment: "Appearance section header")) {
            LiquidPickerRow(
                icon: "paintbrush.fill",
                color: .pink,
                title: NSLocalizedString("theme", comment: "Theme selection label"),
                options: AppTheme.allCases.map { $0.rawValue },
                selection: Binding(
                    get: { themeManager.currentTheme.rawValue },
                    set: { newValue in
                        if let theme = AppTheme(rawValue: newValue) {
                            themeManager.currentTheme = theme
                        }
                    }
                ),
                optionsDict: Dictionary(uniqueKeysWithValues: AppTheme.allCases.map { ($0.rawValue, $0.displayName) })
            ) { _ in }
        }
    }

    private var ttsSection: some View {
        LiquidSettingsSection(title: NSLocalizedString("text_to_speech", comment: "Text-to-speech section header")) {
            LiquidPickerRow(
                icon: "waveform",
                color: .indigo,
                title: NSLocalizedString("voice", comment: "Voice selection label"),
                options: Array(voiceOptions.keys).sorted(),
                selection: $selectedVoice,
                optionsDict: voiceOptions
            ) { newValue in
                ttsService.setVoice(newValue)
            }
            
            Divider().padding(.leading, 64)
            
            LiquidSliderRow(
                icon: "speedometer",
                color: .blue,
                title: NSLocalizedString("speech_speed", comment: "Speech speed slider label"),
                value: $ttsPercentage,
                range: Constants.TTS.minPercentage...Constants.TTS.maxPercentage,
                step: 10,
                formatter: { "\(Int($0))%" },
                onChange: { newValue in ttsService.setRate(newValue) }
            )
            
            Divider().padding(.leading, 64)

            LiquidSliderRow(
                icon: "tuningfork",
                color: .purple,
                title: "Pitch",
                value: $ttsPitch,
                range: Constants.TTS.minPitch...Constants.TTS.maxPitch,
                step: 0.1,
                formatter: { "\(Int($0 * 100))%" },
                onChange: { newValue in ttsService.setPitch(newValue) }
            )
            
            Divider().padding(.leading, 64)

            LiquidSliderRow(
                icon: "speaker.wave.2.fill",
                color: .pink,
                title: "Volume",
                value: $ttsVolume,
                range: Constants.TTS.minVolume...Constants.TTS.maxVolume,
                step: 0.1,
                formatter: { "\(Int($0 * 100))%" },
                onChange: { newValue in ttsService.setVolume(newValue) }
            )
            
            Divider().padding(.leading, 64)
            
            LiquidSliderRow(
                icon: "timer",
                color: .orange,
                title: "Pause",
                value: Binding(get: { Float(ttsPause) }, set: { ttsPause = Double($0) }),
                range: Float(Constants.TTS.minPause)...Float(Constants.TTS.maxPause),
                step: 0.1,
                formatter: { String(format: "%.1fs", $0) },
                onChange: { newValue in ttsService.setPause(Double(newValue)) }
            )
            
            Divider().padding(.leading, 64)

            LiquidSettingsButton(
                icon: "play.fill",
                color: .green,
                title: "Test Voice"
            ) {
                UIImpactFeedbackGenerator.lightImpact()
                ttsService.speak("Hello! This is a test of the selected voice and speed.")
            }
        }
    }

    private var aboutSection: some View {
        LiquidSettingsSection(title: "About") {
            LiquidSettingsRow(
                icon: "info.circle",
                iconColor: .gray,
                title: "English Thought",
                subtitle: "Version \(appVersion)"
            ) {
                 Text(NSLocalizedString("app_description", value: "Learn English patterns", comment: "Short app description"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider().padding(.leading, 64)
            
            LiquidSettingsButton(
                icon: "graduationcap.fill",
                color: .purple,
                title: "Replay Onboarding"
            ) {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    coordinator.presentFullScreen(.onboarding)
                }
            }
        }
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