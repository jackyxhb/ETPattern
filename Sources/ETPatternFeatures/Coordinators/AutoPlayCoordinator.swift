import SwiftUI

@MainActor
public protocol AutoPlayCoordinatorProtocol: AnyObject {
    func dismiss()
}

@MainActor
public class AutoPlayCoordinator: ObservableObject, AutoPlayCoordinatorProtocol {
    var onDismiss: (() -> Void)?
    
    public init(onDismiss: (() -> Void)? = nil) {
        self.onDismiss = onDismiss
    }
    
    public func dismiss() {
        onDismiss?()
    }
}
