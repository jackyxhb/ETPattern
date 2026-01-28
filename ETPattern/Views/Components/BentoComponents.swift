//
//  BentoComponents.swift
//  ETPattern
//
//  Created by admin on 28/01/2026.
//

import SwiftUI

// MARK: - Modifiers

struct LiquidGlassModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(.white.opacity(0.1), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

extension View {
    func liquidGlass() -> some View {
        self.modifier(LiquidGlassModifier())
    }
    
    func bentoTile() -> some View {
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .liquidGlass()
    }
}

// MARK: - Components

struct BentoGrid<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                content
            }
            .padding(16)
        }
    }
}

struct BentoRow<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        HStack(spacing: 12) {
            content
        }
    }
}
