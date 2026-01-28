//
//  ViewModifiers.swift
//  ETPattern
//
//  Extracted from SharedViews.swift for testability.
//

import SwiftUI
import Translation

// MARK: - Alert Modifiers

struct SharedConfirmationAlert: ViewModifier {
    @Environment(\.theme) var theme
    let title: String
    let message: String
    let actionTitle: String
    let isPresented: Binding<Bool>
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .alert(title, isPresented: isPresented) {
                Button("Cancel", role: .cancel) { }
                Button(actionTitle, action: action)
            } message: {
                Text(message)
                    .dynamicTypeSize(.large ... .accessibility5)
            }
    }
}

struct SharedErrorAlert: ViewModifier {
    @Environment(\.theme) var theme
    let title: String
    let message: String
    let isPresented: Binding<Bool>

    func body(content: Content) -> some View {
        content
            .alert(title, isPresented: isPresented) {
                Button("OK") { }
            } message: {
                Text(message)
                    .dynamicTypeSize(.large ... .accessibility5)
            }
    }
}

// MARK: - Theme Modifiers

struct ThemedGlassBackground: ViewModifier {
    @Environment(\.theme) var theme
    
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
    }
}

struct ThemedPresentation: ViewModifier {
    @Environment(\.theme) var theme
    
    func body(content: Content) -> some View {
        content
            .presentationBackground(.ultraThinMaterial)
            .presentationCornerRadius(theme.metrics.cornerRadius)
    }
}

// MARK: - View Extensions

extension View {
    func confirmationAlert(
        title: String,
        message: String,
        actionTitle: String,
        isPresented: Binding<Bool>,
        action: @escaping () -> Void
    ) -> some View {
        modifier(SharedConfirmationAlert(
            title: title,
            message: message,
            actionTitle: actionTitle,
            isPresented: isPresented,
            action: action
        ))
    }

    func errorAlert(
        title: String,
        message: String,
        isPresented: Binding<Bool>
    ) -> some View {
        modifier(SharedErrorAlert(
            title: title,
            message: message,
            isPresented: isPresented
        ))
    }

    func themedGlassBackground() -> some View {
        modifier(ThemedGlassBackground())
    }

    func themedPresentation() -> some View {
        modifier(ThemedPresentation())
    }

    @ViewBuilder
    func safeAppTranslationTask(action: @escaping (TranslationSession) async -> Void) -> some View {
        #if targetEnvironment(simulator)
        self
        #else
        self.translationTask(
            TranslationSession.Configuration(
                source: Locale.Language(identifier: "en"),
                target: Locale.Language(identifier: "zh")
            )
        ) { session in
            await action(session)
        }
        #endif
    }
}
