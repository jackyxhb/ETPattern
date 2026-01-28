//
//  AppCoordinator.swift
//  ETPattern
//
//  Created by admin on 28/01/2026.
//

import SwiftUI
import SwiftData

/// The Coordinator responsible for managing the app's navigation state.
/// Follows the MVVM+ architecture pattern.
@Observable @MainActor
final class AppCoordinator {
    var path = NavigationPath()
    var sheet: SheetDestination?
    var fullScreenCover: FullScreenCoverDestination?
    
    enum SheetDestination: Identifiable, Hashable {
        case settings
        case browse(CardSet)
        
        var id: String {
            switch self {
            case .settings: return "settings"
            case .browse(let deck): return "browse_\(deck.id)"
            }
        }
    }
    
    enum FullScreenCoverDestination: Identifiable, Hashable {
        case study(CardSet)
        case autoPlay(CardSet)
        case masteryDashboard
        case importCSV
        case sessionStats
        case onboarding
        
        var id: String {
            switch self {
            case .study(let deck): return "study_\(deck.id)"
            case .autoPlay(let deck): return "autoplay_\(deck.id)"
            case .masteryDashboard: return "mastery"
            case .importCSV: return "import"
            case .sessionStats: return "sessionStats"
            case .onboarding: return "onboarding"
            }
        }
    }
    
    // MARK: - Navigation Actions
    
    func navigate(to destination: AnyHashable) {
        // Handle push navigation if we have nested views in the future
        // For now, the Dashboard is the root, and most actions are sheets/covers
        path.append(destination)
    }
    
    func presentSheet(_ destination: SheetDestination) {
        sheet = destination
    }
    
    func presentFullScreen(_ destination: FullScreenCoverDestination) {
        fullScreenCover = destination
    }
    
    func dismissSheet() {
        sheet = nil
    }
    
    func dismissFullScreen() {
        fullScreenCover = nil
    }
    
    func popToRoot() {
        path.removeLast(path.count)
    }
}
