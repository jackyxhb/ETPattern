import Foundation
@testable import ETPatternServices

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
