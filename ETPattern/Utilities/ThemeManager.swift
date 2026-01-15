import SwiftUI
import Combine

enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .system: return NSLocalizedString("theme_system", comment: "System theme option")
        case .light: return NSLocalizedString("theme_light", comment: "Light theme option")
        case .dark: return NSLocalizedString("theme_dark", comment: "Dark theme option")
        }
    }
}

class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme = .system {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "appTheme")
        }
    }
    
    init() {
        let savedValue = UserDefaults.standard.string(forKey: "appTheme") ?? AppTheme.dark.rawValue
        self.currentTheme = AppTheme(rawValue: savedValue) ?? .dark
    }
    
    var theme: Theme {
        switch currentTheme {
        case .light:
            return Theme.light
        case .dark:
            return Theme.dark
        case .system:
            // In system mode, we return the theme matching the current system scheme.
            // However, since we can't easily detect that synchronously here without @Environment,
            // we will rely on the App wrapper to inject the correct one based on ColorScheme.
            // For default purposes (fallback), we return dark as that's the "brand" look.
            return Theme.dark
        }
    }
    
    var colorScheme: ColorScheme? {
        switch currentTheme {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil
        }
    }
    
    static let shared = ThemeManager()
}
