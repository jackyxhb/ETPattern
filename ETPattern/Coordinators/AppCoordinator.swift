import SwiftUI
import Combine
import ETPatternModels

@MainActor
class AppCoordinator: ObservableObject {
    @Published var navigationPath = NavigationPath()
    
    // Child coordinators can be stored here if needed
    // var studyCoordinator: StudyCoordinator?
    
    func navigateToStudy() {
        // Logic to transition to study mode
        // In the new architecture, ContentView might invoke this
    }
}
