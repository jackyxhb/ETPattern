import Foundation
@testable import ETPatternFeatures

@MainActor
final class MockAutoPlayCoordinator: AutoPlayCoordinatorProtocol {
    var dismissCalled = false
    
    func dismiss() {
        dismissCalled = true
    }
}
