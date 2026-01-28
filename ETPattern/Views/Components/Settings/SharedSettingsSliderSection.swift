//
//  SharedSettingsSliderSection.swift
//  ETPattern
//
//  Extracted from SharedViews.swift for testability.
//

import SwiftUI

struct SharedSettingsSliderSection<T: BinaryFloatingPoint>: View {
    @Environment(\.theme) var theme
    let label: String
    @Binding var value: T
    let minValue: T
    let maxValue: T
    let step: T
    let minLabel: String
    let maxLabel: String
    let valueFormatter: (T) -> String
    let onChange: (T) -> Void

    init(label: String, value: Binding<T>, minValue: T, maxValue: T, step: T, minLabel: String, maxLabel: String, valueFormatter: @escaping (T) -> String = { "\($0)" }, onChange: @escaping (T) -> Void) {
        self.label = label
        self._value = value
        self.minValue = minValue
        self.maxValue = maxValue
        self.step = step
        self.minLabel = minLabel
        self.maxLabel = maxLabel
        self.valueFormatter = valueFormatter
        self.onChange = onChange
    }

    var body: some View {
        VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
            Text("\(label): \(valueFormatter(value))")
                .font(theme.metrics.subheadline)
                .foregroundColor(theme.colors.textPrimary)
                .dynamicTypeSize(.large ... .accessibility5)

            Slider(value: Binding(
                get: { Double(value) },
                set: { value = T($0) }
            ), in: Double(minValue)...Double(maxValue), step: Double(step)) {
                Text(label)
                    .foregroundColor(theme.colors.textPrimary)
                    .dynamicTypeSize(.large ... .accessibility5)
            } minimumValueLabel: {
                Text(minLabel)
                    .font(theme.metrics.caption)
                    .foregroundColor(theme.colors.textSecondary)
                    .dynamicTypeSize(.large ... .accessibility5)
            } maximumValueLabel: {
                Text(maxLabel)
                    .font(theme.metrics.caption)
                    .foregroundColor(theme.colors.textSecondary)
                    .dynamicTypeSize(.large ... .accessibility5)
            }
            .tint(theme.colors.highlight)
            .onChange(of: value) { _, newValue in
                onChange(newValue)
            }
        }
        .padding(.vertical, theme.metrics.smallSpacing)
        .listRowBackground(theme.colors.surfaceLight)
    }
}
