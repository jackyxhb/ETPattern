//
//  SharedSettingsPickerSection.swift
//  ETPattern
//
//  Extracted from SharedViews.swift for testability.
//

import SwiftUI

struct SharedSettingsPickerSection: View {
    @Environment(\.theme) var theme
    let header: String
    let label: String
    let options: [String: String]
    @Binding var selection: String
    let userDefaultsKey: String?
    let onChange: ((String) -> Void)?

    init(header: String, label: String, options: [String: String], selection: Binding<String>, userDefaultsKey: String) {
        self.header = header
        self.label = label
        self.options = options
        self._selection = selection
        self.userDefaultsKey = userDefaultsKey
        self.onChange = nil
    }

    init(header: String, label: String, options: [String: String], selection: Binding<String>, onChange: @escaping (String) -> Void) {
        self.header = header
        self.label = label
        self.options = options
        self._selection = selection
        self.userDefaultsKey = nil
        self.onChange = onChange
    }

    var body: some View {
        Section(header: Text(header).foregroundColor(theme.colors.textPrimary).dynamicTypeSize(.large ... .accessibility5)) {
            SharedThemedPicker(
                label: label,
                options: options,
                selection: $selection,
                onChange: { newValue in
                    if let userDefaultsKey = userDefaultsKey {
                        UserDefaults.standard.set(newValue, forKey: userDefaultsKey)
                    } else if let onChange = onChange {
                        onChange(newValue)
                    }
                }
            )
        }
        .listRowBackground(theme.colors.surfaceLight)
    }
}
