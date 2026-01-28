//
//  StatsService.swift
//  ETPattern
//
//  Created by admin on 28/01/2026.
//

import Foundation
import SwiftUI

protocol StatsServiceProtocol: Sendable {
    func getDailyReviewCount() -> Int
    func incrementDailyReviewCount()
    func resetDailyCountIfNeeded()
}

@Observable
final class StatsService: StatsServiceProtocol {
    private let userDefaults: UserDefaults
    private let calendar: Calendar
    
    // Keys
    private let keyDailyCount = "stats.dailyReviewCount"
    private let keyLastReviewDate = "stats.lastReviewDate"
    
    static let shared = StatsService()
    
    var dailyReviewCount: Int = 0
    
    init(userDefaults: UserDefaults = .standard, calendar: Calendar = .current) {
        self.userDefaults = userDefaults
        self.calendar = calendar
        resetDailyCountIfNeeded()
        // Initialize from storage
        self.dailyReviewCount = userDefaults.integer(forKey: keyDailyCount)
    }
    
    func getDailyReviewCount() -> Int {
        return dailyReviewCount
    }
    
    func incrementDailyReviewCount() {
        resetDailyCountIfNeeded()
        dailyReviewCount += 1
        userDefaults.set(dailyReviewCount, forKey: keyDailyCount)
        userDefaults.set(Date(), forKey: keyLastReviewDate)
    }
    
    func resetDailyCountIfNeeded() {
        guard let lastDate = userDefaults.object(forKey: keyLastReviewDate) as? Date else {
            return // No previous date, start fresh or keep 0
        }
        
        if !calendar.isDateInToday(lastDate) {
            dailyReviewCount = 0
            userDefaults.set(0, forKey: keyDailyCount)
        }
    }
}
