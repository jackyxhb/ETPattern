import SwiftUI
import Foundation

/// Simple wrapper that overlays a branded splash while main content loads.
struct SplashHostView<Content: View>: View {
    private let content: () -> Content
    @State private var showSplash = true

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        ZStack {
            content()
                .opacity(showSplash ? 0 : 1)
                .animation(.easeOut(duration: 0.3), value: showSplash)

            if showSplash {
                SplashView()
                    .transition(.opacity)
            }
        }
        .task {
            guard showSplash else { return }
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            withAnimation(.easeInOut(duration: 0.4)) {
                showSplash = false
            }
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
                    .shadow(color: theme.colors.shadow, radius: theme.metrics.splashShadowRadius, y: theme.metrics.splashShadowY)

                Text(NSLocalizedString("english_thought", comment: "App name on splash screen"))
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                Text(NSLocalizedString("300_expression_patterns", comment: "App tagline on splash screen"))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .tracking(0.5)
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
