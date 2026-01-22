import SwiftUI
import Combine
import ETPatternModels

@MainActor
public class BrowseCoordinator: ObservableObject {
    @Published public var previewCard: CardDisplayModel?
    @Published public var editingCard: CardDisplayModel?
    @Published public var showingImport: Bool = false
    
    private let onDismiss: () -> Void
    
    public init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
    }
    
    public func dismiss() {
        onDismiss()
    }
    
    public func presentPreview(for card: CardDisplayModel) {
        self.previewCard = card
    }
    
    public func dismissPreview() {
        self.previewCard = nil
    }
    
    public func presentEdit(for card: CardDisplayModel?) {
        self.editingCard = card
    }
    
    public func dismissEdit() {
        self.editingCard = nil
    }
    
    public func presentImport() {
        self.showingImport = true
    }
    
    public func dismissImport() {
        self.showingImport = false
        onDismiss()
    }
}
