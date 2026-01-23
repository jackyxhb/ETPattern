import SwiftUI
import ETPatternModels

@MainActor
public protocol StudyCoordinatorProtocol: AnyObject {
    func dismiss()
    func showSettings()
    func showSessionStats()
}

@MainActor
public class StudyCoordinator: ObservableObject, StudyCoordinatorProtocol {
    @Published public var navigationPath = NavigationPath()
    @Published public var isSettingsPresented = false
    @Published var isStatsPresented = false
    
    // Parent coordinator or closure to handle dismissal from the flow
    var onDismiss: (() -> Void)?
    
    public init(onDismiss: (() -> Void)? = nil) {
        self.onDismiss = onDismiss
    }
    
    public func dismiss() {
        onDismiss?()
    }
    
    public func showSettings() {
        isSettingsPresented = true
    }
    
    public func showSessionStats() {
        isStatsPresented = true
    }
}
