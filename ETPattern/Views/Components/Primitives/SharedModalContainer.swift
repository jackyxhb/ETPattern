//
//  SharedModalContainer.swift
//  ETPattern
//
//  Extracted from SharedViews.swift for testability.
//

import SwiftUI

struct SharedModalContainer<Content: View>: View {
    @Environment(\.theme) var theme
    let content: Content
    let onClose: () -> Void

    init(onClose: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.onClose = onClose
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            content

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundColor(theme.colors.textPrimary)
                    .padding(theme.metrics.modalCloseButtonPadding)
                    .background(theme.colors.textPrimary.opacity(0.2), in: Circle())
                    .padding()
            }
            .accessibilityLabel("Close")
        }
    }
}
