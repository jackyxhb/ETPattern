//
//  LiquidSettingsComponents.swift
//  ETPattern
//
//  Created by admin on 28/01/2026.
//

import SwiftUI

struct LiquidSettingsSection<Content: View>: View {
    @Environment(\.theme) var theme
    let title: String?
    let content: Content
    
    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title = title {
                Text(title)
                    .font(theme.metrics.headline)
                    .foregroundColor(theme.colors.textSecondary) // Slightly muted header
                    .padding(.leading, 4)
            }
            
            VStack(spacing: 1) { // 1px spacing for separators if needed, or 0
                content
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .liquidGlass() // Apply the glass effect to the whole section
        }
        .padding(.horizontal)
    }
}

struct LiquidSettingsRow<Content: View>: View {
    @Environment(\.theme) var theme
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    let content: Content
    
    init(icon: String, iconColor: Color = .blue, title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon Container
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(theme.colors.textPrimary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
            
            Spacer()
            
            content
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.white.opacity(0.01)) // Capture touches
    }
}


// Convenience for simple Navigation links or Buttons
struct LiquidSettingsButton: View {
    let icon: String
    let color: Color
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            LiquidSettingsRow(icon: icon, iconColor: color, title: title) {
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundColor(.secondary.opacity(0.6))
            }
        }
        .buttonStyle(.plain)
    }
}
