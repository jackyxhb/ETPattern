import SwiftUI
import ETPatternCore

// MARK: - Design System Modifiers

extension View {
    
    /// Applies the standard "Bento Tile" style:
    /// - UltraThin material background
    /// - 28pt corner radius (Squircle)
    /// - Subtle white inner stroke for depth
    /// - Standard padding
    func bentoTileStyle() -> some View {
        self.padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(.white.opacity(0.1), lineWidth: 0.5)
            )
    }
    
    /// Applies the "Liquid Glass" effect:
    /// - Luminosity blend mode for vibrancy
    /// - Soft shadow for elevation
    func liquidGlassEffect() -> some View {
        self.background {
            Rectangle()
                .fill(.ultraThinMaterial) // or just .ultraThinMaterial if supported as View
                .visualEffect { content, proxy in
                    content.blendMode(.luminosity)
                }
        }
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    /// Standard primary button style
    func standardButtonStyle() -> some View {
        self.font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                Capsule()
                    .fill(Color.accentColor.gradient)
            )
            .shadow(color: .accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Reusable Components

/// A standard background view that provides the base "Liquid" environment
struct LiquidBackground: View {
    var body: some View {
        ZStack {
            // Base gradient (placeholder - ideally this comes from Theme)
            LinearGradient(
                colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Blur layer to create the glass feel
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
        }
    }
}
