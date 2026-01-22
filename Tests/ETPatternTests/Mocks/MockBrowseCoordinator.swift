import Foundation
@testable import ETPatternServices

@MainActor
final class MockBrowseCoordinator: BrowseCoordinator {
    var dismissEditCalled = false
    var dismissImportCalled = false
    var dismissCalledCount = 0
    
    init() {
        super.init(onDismiss: {})
    }
    
    override func dismissEdit() {
        dismissEditCalled = true
        dismissCalledCount += 1
        super.dismissEdit()
    }
    
    override func dismissImport() {
        dismissImportCalled = true
        dismissCalledCount += 1
        super.dismissImport()
    }
}
