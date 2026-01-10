import SwiftUI
import Foundation
import ETPatternServices

/// Simple wrapper that overlays a branded splash while main content loads.
struct SplashHostView<Content: View>: View {
    private let content: () -> Content
    @StateObject private var appInitManager = AppInitManager.shared
    @Environment(\.theme) var theme

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        ZStack {
            if appInitManager.isReady {
                content()
                    .transition(.opacity)
            }

            if !appInitManager.isReady {
                SplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .animation(.easeOut(duration: theme.metrics.splashFadeOutDuration), value: appInitManager.isReady)
        .task {
            await appInitManager.initializeApp()
        }
    }
}

struct SplashView: View {
    @Environment(\.theme) var theme

    var body: some View {
        ZStack {
            theme.gradients.background
                .ignoresSafeArea()

            VStack(spacing: theme.metrics.splashSpacing) {
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: theme.metrics.splashLogoSize, height: theme.metrics.splashLogoSize)
                    .clipShape(RoundedRectangle(cornerRadius: theme.metrics.splashLogoSize * 0.223)) // iOS icon corner radius
                    .shadow(color: theme.colors.shadow.opacity(0.3), radius: 20, x: 0, y: 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.metrics.splashLogoSize * 0.223)
                            .stroke(.white.opacity(0.1), lineWidth: 0.5)
                    )

                VStack(spacing: 8) {
                    Text(NSLocalizedString("english_thought", comment: "App name on splash screen"))
                        .font(theme.metrics.title.bold())
                        .foregroundStyle(theme.colors.textPrimary)
                    
                    Text(NSLocalizedString("300_expression_patterns", comment: "App tagline on splash screen"))
                        .font(.subheadline)
                        .foregroundStyle(theme.colors.textSecondary)
                        .tracking(1.0)
                }
            }
            .padding(theme.metrics.splashPadding)
        }
    }
}

#Preview {
    SplashHostView {
        Text("Content")
    }
}
