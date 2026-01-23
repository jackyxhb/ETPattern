import Foundation
import CoreData
import Combine

@MainActor
final class CloudSyncManager: ObservableObject {
    static let shared = CloudSyncManager()
    
    @Published private(set) var lastSyncDate: Date?
    @Published private(set) var isSyncing: Bool = false
    @Published private(set) var syncError: Error?
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupObservers()
    }
    
    private func setupObservers() {
        NotificationCenter.default.publisher(for: NSPersistentCloudKitContainer.eventChangedNotification)
            .sink { [weak self] notification in
                self?.handleCloudKitEvent(notification)
            }
            .store(in: &cancellables)
    }
    
    private func handleCloudKitEvent(_ notification: Notification) {
        guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] as? NSPersistentCloudKitContainer.Event else {
            return
        }
        
        Task { @MainActor in
            if event.endDate == nil {
                self.isSyncing = true
            } else {
                self.isSyncing = false
                if let error = event.error {
                    self.syncError = error
                } else {
                    self.syncError = nil
                    self.lastSyncDate = event.endDate
                }
            }
        }
    }
}
