//
//  SettingsView.swift
//  ETPattern
//

import SwiftUI
import AVFoundation
import ETPatternServices
import ETPatternCore
import ETPatternServices

public struct SettingsView: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) private var dismiss
    
    @State private var viewModel: SettingsViewModel
    
    public init(ttsService: TTSService = .shared) {
        _viewModel = State(initialValue: SettingsViewModel(ttsService: ttsService))
    }
    
    public init(viewModel: SettingsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        @Bindable var viewModel = viewModel
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
    }

    private var studyModeSection: some View {
        let bindingCardOrder = Binding(
            get: { viewModel.cardOrderMode },
            set: { viewModel.updateCardOrder($0) }
        )
        let bindingAutoPlayOrder = Binding(
            get: { viewModel.autoPlayOrderMode },
            set: { viewModel.updateAutoPlayOrder($0) }
        )
        
        return Group {
            SharedSettingsPickerSection(
                header: NSLocalizedString("study_mode", comment: "Study mode section header"),
                label: NSLocalizedString("card_order", comment: "Card order label"),
                options: viewModel.orderOptions,
                selection: bindingCardOrder,
                onChange: { _ in }
            )

            SharedSettingsPickerSection(
                header: NSLocalizedString("auto_play_mode", comment: "Auto play mode section header"),
                label: NSLocalizedString("card_order", comment: "Card order label"),
                options: viewModel.orderOptions,
                selection: bindingAutoPlayOrder,
                onChange: { _ in }
            )
        }
    }

    private var appearanceSection: some View {
        SharedSettingsPickerSection(
            header: NSLocalizedString("appearance", comment: "Appearance section header"),
            label: NSLocalizedString("theme", comment: "Theme selection label"),
            options: Dictionary(uniqueKeysWithValues: AppTheme.allCases.map { ($0.rawValue, $0.displayName) }),
            selection: Binding(
                get: { viewModel.currentTheme.rawValue },
                set: { newValue in
                    if let theme = AppTheme(rawValue: newValue) {
                        viewModel.currentTheme = theme
                    }
                }
            ),
            onChange: { _ in }
        )
    }

    private var ttsSection: some View {
        @Bindable var viewModel = viewModel
        return Group {
            // Voice picker with section header
            SharedSettingsPickerSection(
                header: NSLocalizedString("text_to_speech", comment: "Text-to-speech section header"),
                label: NSLocalizedString("voice", comment: "Voice selection label"),
                options: viewModel.voiceOptions,
                selection: Binding(
                    get: { viewModel.selectedVoice },
                    set: { viewModel.updateVoice($0) }
                ),
                onChange: { _ in }
            )

            // Remaining TTS controls in a continuation section (no header)
            Section {
                VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                    Text(String(format: NSLocalizedString("speech_speed_value", comment: "Speech speed display with percentage"), Int(viewModel.ttsPercentage)))
                        .font(theme.metrics.subheadline)
                        .foregroundColor(theme.colors.textPrimary)
                        .dynamicTypeSize(.large ... .accessibility5)

                    GeometryReader { geometry in
                        Slider(value: $viewModel.ttsPercentage, in: Constants.TTS.minPercentage...Constants.TTS.maxPercentage, step: 10) {
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
                                    let percentageValue = Constants.TTS.minPercentage + (Constants.TTS.maxPercentage - Constants.TTS.minPercentage) * Float(percentage)
                                    let steppedValue = round(percentageValue / 10) * 10
                                    let clampedValue = min(max(steppedValue, Constants.TTS.minPercentage), Constants.TTS.maxPercentage)
                                    viewModel.updateRate(clampedValue)
                                }
                        )
                        .onChange(of: viewModel.ttsPercentage) { _, newValue in
                            viewModel.updateRate(newValue)
                        }
                    }
                    .frame(height: theme.metrics.sliderHeight)
                }
                .padding(.vertical, theme.metrics.smallSpacing)

                SharedSettingsSliderSection(
                    label: "Pitch",
                    value: $viewModel.ttsPitch,
                    minValue: Constants.TTS.minPitch,
                    maxValue: Constants.TTS.maxPitch,
                    step: 0.1,
                    minLabel: "50%",
                    maxLabel: "200%",
                    valueFormatter: { "\(Int($0 * 100))%" },
                    onChange: { newValue in
                        viewModel.updatePitch(newValue)
                    }
                )

                SharedSettingsSliderSection(
                    label: "Volume",
                    value: $viewModel.ttsVolume,
                    minValue: Constants.TTS.minVolume,
                    maxValue: Constants.TTS.maxVolume,
                    step: 0.1,
                    minLabel: "0%",
                    maxLabel: "100%",
                    valueFormatter: { "\(Int($0 * 100))%" },
                    onChange: { newValue in
                        viewModel.updateVolume(newValue)
                    }
                )

                SharedSettingsSliderSection(
                    label: "Pause",
                    value: $viewModel.ttsPause,
                    minValue: Float(Constants.TTS.minPause),
                    maxValue: Float(Constants.TTS.maxPause),
                    step: 0.1,
                    minLabel: "0s",
                    maxLabel: "2s",
                    valueFormatter: { String(format: "%.1f", $0) + "s" },
                    onChange: { newValue in
                        viewModel.updatePause(newValue)
                    }
                )

                Button("Test Voice") {
                    viewModel.testVoice()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(theme.gradients.accent)
                .foregroundColor(theme.colors.textPrimary)
                .cornerRadius(theme.metrics.cornerRadius)
            }
            .listRowBackground(theme.colors.surfaceLight)
        }
    }

    private var aboutSection: some View {
        Section(header: Text("About").foregroundColor(theme.colors.textPrimary).dynamicTypeSize(.large ... .accessibility5)) {
            Text("English Thought")
                .font(theme.metrics.headline)
                .foregroundColor(theme.colors.textPrimary)
                .dynamicTypeSize(.large ... .accessibility5)
            Text(viewModel.appVersion)
                .foregroundColor(theme.colors.textSecondary)
                .dynamicTypeSize(.large ... .accessibility5)
            Text("Learn English patterns with spaced repetition")
                .foregroundColor(theme.colors.textSecondary)
                .font(theme.metrics.caption)
                .dynamicTypeSize(.large ... .accessibility5)
        }
        .listRowBackground(theme.colors.surfaceLight)
    }
}

#Preview {
    NavigationView {
        SettingsView()
    }
}