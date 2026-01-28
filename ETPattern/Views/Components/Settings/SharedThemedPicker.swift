//
//  SharedThemedPicker.swift
//  ETPattern
//
//  Extracted from SharedViews.swift for testability.
//

import SwiftUI

struct SharedThemedPicker: View {
    @Environment(\.theme) var theme
    let label: String
    let options: [String: String]
    @Binding var selection: String
    let onChange: ((String) -> Void)?
    
    @State private var isPresented = false

    var body: some View {
        Button(action: {
            isPresented = true
        }) {
            HStack {
                Text(label)
                    .foregroundColor(theme.colors.textPrimary)
                Spacer()
                Text(options[selection] ?? selection)
                    .foregroundColor(theme.colors.highlight)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $isPresented) {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(options.keys.sorted(), id: \.self) { key in
                            Button(action: {
                                selection = key
                                onChange?(key)
                                isPresented = false
                            }) {
                                HStack {
                                    Text(options[key] ?? key)
                                        .foregroundColor(theme.colors.textPrimary)
                                    Spacer()
                                    if selection == key {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(theme.colors.highlight)
                                    }
                                }
                                .padding()
                                .background(selection == key ? theme.colors.surfaceMedium : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
            .presentationDetents([.fraction(0.4), .medium])
            .presentationDragIndicator(.visible)
            .themedPresentation()
        }
    }
}
