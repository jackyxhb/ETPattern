//
//  Theme.swift
//  ETPattern
//
//  Created by admin on 18/12/2025.
//

import SwiftUI

struct Theme {
    let gradients: Gradients
    let colors: Colors
    let metrics: Metrics
    let typography: Typography

    static let `default` = Theme(
        gradients: Gradients(),
        colors: Colors(),
        metrics: Metrics(),
        typography: Typography()
    )

    struct Gradients {
        let background = LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.05, green: 0.05, blue: 0.15),
                Color(red: 0.1, green: 0.1, blue: 0.2),
                Color(red: 0.15, green: 0.15, blue: 0.25)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )

        let card = LinearGradient(
            gradient: Gradient(colors: [
                Color.white.opacity(0.1),
                Color.white.opacity(0.05)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )

        let accent = LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.3, green: 0.6, blue: 1.0),
                Color(red: 0.2, green: 0.5, blue: 0.9)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )

        let success = LinearGradient(
            gradient: Gradient(colors: [
                Color.green.opacity(0.8),
                Color.green.opacity(0.6)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )

        let danger = LinearGradient(
            gradient: Gradient(colors: [
                Color.red.opacity(0.8),
                Color.red.opacity(0.6)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )

        let warning = LinearGradient(
            gradient: Gradient(colors: [
                Color.orange.opacity(0.8),
                Color.orange.opacity(0.6)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )

        let neutral = LinearGradient(
            gradient: Gradient(colors: [
                Color.teal.opacity(0.8),
                Color.teal.opacity(0.6)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    struct Colors {
        // Background colors
        let background = Color(red: 0.05, green: 0.05, blue: 0.15)
        let onBackground = Color.white
        
        // Surface colors (elevated)
        let surface = Color.white.opacity(0.1)
        let onSurface = Color.white
        let surfaceVariant = Color.white.opacity(0.05)
        let onSurfaceVariant = Color.white.opacity(0.8)
        
        // Elevated surface for menus/popovers
        let surfaceElevated = Color.white.opacity(0.95)
        let onSurfaceElevated = Color.black.opacity(0.8)
        
        // Outline/border
        let outline = Color.white.opacity(0.2)
        
        // Legacy colors (keeping for compatibility)
        let backgroundStart = Color(red: 0.05, green: 0.05, blue: 0.15)
        let backgroundEnd = Color(red: 0.15, green: 0.15, blue: 0.25)
        let highlight = Color(red: 0.3, green: 0.6, blue: 1.0)
        let surfaceLight = Color.white.opacity(0.15)
        let surfaceMedium = Color.white.opacity(0.1)
        let shadow = Color.black.opacity(0.3)
        let textPrimary = Color.white
        let textSecondary = Color.white.opacity(0.7)
        let success = Color.green
        let warning = Color.orange
        let danger = Color.red
    }

    struct Metrics {
        let cornerRadius: CGFloat = 20.0
        let shadowRadius: CGFloat = 14.0
        let shadowY: CGFloat = 10.0
        let standardSpacing: CGFloat = 8.0
        let smallSpacing: CGFloat = 4.0
        let mediumSpacing: CGFloat = 16.0
        let largeSpacing: CGFloat = 24.0
        let buttonPadding: CGFloat = 16.0
        let sliderHeight: CGFloat = 44.0
    }

    struct Typography {
        let headline = Font.headline
        let subheadline = Font.subheadline
        let body = Font.body
        let caption = Font.caption
        let title = Font.title
        let title2 = Font.title2
        let title3 = Font.title3
    }
}

private struct ThemeKey: EnvironmentKey {
    static let defaultValue = Theme.default
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

extension View {
    func theme(_ theme: Theme) -> some View {
        environment(\.theme, theme)
    }
}