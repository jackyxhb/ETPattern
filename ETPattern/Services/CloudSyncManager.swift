import Foundation
import CoreData
import Combine

@MainActor
final class CloudSyncManager: ObservableObject {
    static let shared = CloudSyncManager()
    
    @Published private(set) var lastSyncDate: Date?
    @Published private(set) var isSyncing: Bool = false
    @Published private(set) var syncError: Error?
    @Published private(set) var statusLog: String = "Init..."
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupObservers()
    }
    
    private func setupObservers() {
        statusLog = "Observing..."
        NotificationCenter.default.publisher(for: NSPersistentCloudKitContainer.eventChangedNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleCloudKitEvent(notification)
            }
            .store(in: &cancellables)
    }
    
    private func handleCloudKitEvent(_ notification: Notification) {
        guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] as? NSPersistentCloudKitContainer.Event else {
            statusLog = "Rx Notif (Invalid userInfo)"
            return
        }
        
        Task { @MainActor in
            if event.endDate == nil {
                self.isSyncing = true
                self.statusLog = "Syncing (ID: \(event.identifier.uuidString.prefix(4)))"
            } else {
                self.isSyncing = false
                if let error = event.error {
                    self.syncError = error
                    self.statusLog = "Error: \(error.localizedDescription)"
                } else {
                    self.syncError = nil
                    self.lastSyncDate = event.endDate
                    self.statusLog = "Success: \(event.endDate?.formatted() ?? "Now")"
                }
            }
        }
    }
}
