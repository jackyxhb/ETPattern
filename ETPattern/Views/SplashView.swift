import SwiftUI
import Foundation

/// Simple wrapper that overlays a branded splash while main content loads.
struct SplashHostView<Content: View>: View {
    private let content: () -> Content
    @State private var showSplash = true

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
        _showSplash = State(initialValue: !ProcessInfo.processInfo.arguments.contains("UI_TESTING"))
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
    private var backgroundGradient: LinearGradient {
        LinearGradient(colors: [
            Color(red: 18/255, green: 22/255, blue: 41/255),
            Color(red: 42/255, green: 49/255, blue: 89/255)
        ], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
                    .shadow(color: Color.black.opacity(0.25), radius: 30, y: 16)

                Text("English Thought")
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                Text("300 Expression Patterns")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .tracking(0.5)
            }
            .padding(32)
        }
    }
}

#Preview {
    SplashHostView {
        Text("Content")
    }
}
