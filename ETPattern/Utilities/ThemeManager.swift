import SwiftUI
import Combine

enum AppTheme: String, CaseIterable, Identifiable {
    case light
    case dark
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .light: return NSLocalizedString("theme_light", comment: "Light theme option")
        case .dark: return NSLocalizedString("theme_dark", comment: "Dark theme option")
        }
    }
}

class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme = .dark {
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
        }
    }
    
    var colorScheme: ColorScheme {
        switch currentTheme {
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
    
    static let shared = ThemeManager()
}
