import Foundation
@testable import ETPatternServices

@MainActor
final class MockAutoPlayCoordinator: AutoPlayCoordinatorProtocol {
    var dismissCalled = false
    
    func dismiss() {
        dismissCalled = true
    }
}
