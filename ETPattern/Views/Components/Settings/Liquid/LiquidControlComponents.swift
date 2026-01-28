//
//  LiquidControlComponents.swift
//  ETPattern
//
//  Created by admin on 28/01/2026.
//

import SwiftUI

struct LiquidSliderRow: View {
    @Environment(\.theme) var theme
    let icon: String
    let color: Color
    let title: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    let step: Float
    let formatter: (Float) -> String
    let onChange: (Float) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            LiquidSettingsRow(icon: icon, iconColor: color, title: title) {
                Text(formatter(value))
                    .font(.subheadline.monospacedDigit())
                    .foregroundColor(.secondary)
            }
            
            Slider(value: $value, in: range, step: step)
                .tint(color)
                .padding(.leading, 64) // Align with text
                .padding(.trailing, 16)
                .padding(.bottom, 8)
                .onChange(of: value) { _, newValue in
                    onChange(newValue)
                }
        }
    }
}

struct LiquidPickerRow: View {
    @Environment(\.theme) var theme
    let icon: String
    let color: Color
    let title: String
    let options: [String] // Assuming key is value, label is localized
    @Binding var selection: String
    let optionsDict: [String: String] // Key -> Localized Label
    let onChange: (String) -> Void
    
    var body: some View {
        LiquidSettingsRow(icon: icon, iconColor: color, title: title) {
            Menu {
                ForEach(options, id: \.self) { key in
                    Button {
                        selection = key
                        onChange(key)
                    } label: {
                        HStack {
                            Text(optionsDict[key] ?? key)
                            if selection == key {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(optionsDict[selection] ?? selection)
                        .font(.subheadline)
                        .foregroundColor(theme.colors.highlight)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
}
