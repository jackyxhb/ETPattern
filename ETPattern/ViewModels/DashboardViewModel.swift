//
//  DashboardViewModel.swift
//  ETPattern
//
//  Created by admin on 28/01/2026.
//

import Foundation
import SwiftData
import SwiftUI

@Observable @MainActor
final class DashboardViewModel {
    private(set) var decks: [CardSet] = []
    private(set) var isLoading = false
    private(set) var error: Error?
    
    // Quick Actions
    private(set) var totalCardsReviewedToday: Int = 0 // Mock for now
    private(set) var dailyGoal: Int = 50
    
    private let service: CardSetServiceProtocol
    private weak var coordinator: AppCoordinator?
    
    init(service: CardSetServiceProtocol, coordinator: AppCoordinator?) {
        self.service = service
        self.coordinator = coordinator
    }
    
    func loadData() async {
        isLoading = true
        do {
            decks = try await service.fetchCardSets()
            // In a real app, we would also fetch "Today's Progress" from a StatsService
            calculateMockStats()
            error = nil
        } catch {
            self.error = error
        }
        isLoading = false
    }
    
    func createDeck(name: String) async {
        guard !name.isEmpty else { return }
        do {
            _ = try await service.createCardSet(name: name)
            await loadData() // Refresh list
        } catch {
            self.error = error
        }
    }
    
    // MARK: - Navigation Intents
    
    func showSettings() {
        coordinator?.presentSheet(.settings)
    }
    
    func showQuickStudy() {
        // Logic to find the best deck to study or a "Mixed" session
        if let firstDeck = decks.first {
            coordinator?.presentFullScreen(.study(firstDeck))
        }
    }
    
    func openDeck(_ deck: CardSet) {
        coordinator?.presentSheet(.browse(deck))
    }
    
    func showImport() {
        coordinator?.presentFullScreen(.importCSV)
    }
    
    // MARK: - Helper
    private func calculateMockStats() {
        // Placeholder for future logic
        totalCardsReviewedToday = Int.random(in: 10...40)
    }
    
    var userName: String {
        let deviceName = UIDevice.current.name
        // Try to extract first name if format is "Name's iPhone"
        if let range = deviceName.range(of: "’s iPhone") ?? deviceName.range(of: "'s iPhone") {
            return String(deviceName[..<range.lowerBound])
        }
        // Fallback for just "iPhone" or other names
        return deviceName
    }
}
