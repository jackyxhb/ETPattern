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
    var totalCardsReviewedToday: Int {
        statsService.getDailyReviewCount()
    }
    private(set) var dailyGoal: Int = 50
    
    private let service: CardSetServiceProtocol
    private let statsService: StatsServiceProtocol
    private weak var coordinator: AppCoordinator?
    
    init(service: CardSetServiceProtocol, statsService: StatsServiceProtocol = StatsService.shared, coordinator: AppCoordinator?) {
        self.service = service
        self.statsService = statsService
        self.coordinator = coordinator
    }
    
    func loadData() async {
        isLoading = true
        do {
            decks = try await service.fetchCardSets()
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
    func deleteDeck(_ deck: CardSet) async {
        do {
            try await service.deleteCardSet(deck)
            await loadData()
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
        // Find the first deck that actually has cards
        if let bestDeck = decks.first(where: { !$0.safeCards.isEmpty }) ?? decks.first {
            coordinator?.presentFullScreen(.study(bestDeck))
        }
    }
    
    func openDeck(_ deck: CardSet) {
        coordinator?.presentSheet(.browse(deck))
    }
    
    func openAutoPlay(_ deck: CardSet) {
        coordinator?.presentFullScreen(.autoPlay(deck))
    }
    
    func showImport() {
        coordinator?.presentFullScreen(.importCSV)
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
