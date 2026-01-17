import Foundation
@testable import ETPatternFeatures

@MainActor
final class MockStudyCoordinator: StudyCoordinatorProtocol {
    var dismissCalled = false
    var showSettingsCalled = false
    var showSessionStatsCalled = false
    
    func dismiss() {
        dismissCalled = true
    }
    
    func showSettings() {
        showSettingsCalled = true
    }
    
    func showSessionStats() {
        showSessionStatsCalled = true
    }
}
