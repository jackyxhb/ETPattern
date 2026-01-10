import Foundation
import SwiftData
import ETPatternModels

@MainActor
public final class AnalyticsService {
    private let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Fetches review logs for a specific time range
    public func fetchReviewLogs(days: Int = 30) async throws -> [ReviewLog] {
        let now = Date()
        guard let startDate = Calendar.current.date(byAdding: .day, value: -days, to: now) else {
            return []
        }

        let fetchDescriptor = FetchDescriptor<ReviewLog>(
            predicate: #Predicate<ReviewLog> { $0.date >= startDate },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )

        return try modelContext.fetch(fetchDescriptor)
    }

    /// Agregates daily review counts for bar charts
    public func aggregateDailyActivity(logs: [ReviewLog]) -> [Date: Int] {
        var activity: [Date: Int] = [:]
        let calendar = Calendar.current

        for log in logs {
            let day = calendar.startOfDay(for: log.date)
            activity[day, default: 0] += 1
        }
        return activity
    }

    /// Calculates retention rate (percentage of "Again" ratings vs others)
    public func calculateRetentionRate(logs: [ReviewLog]) -> Double {
        guard !logs.isEmpty else { return 0.0 }
        
        let successfulReviews = logs.filter { log in
            // DifficultyRating.again check
            log.ratingValue > 0 
        }.count

        return (Double(successfulReviews) / Double(logs.count)) * 100.0
    }

    /// Categorizes all cards in the database by maturity
    public func getMaturityDistribution() async throws -> (new: Int, learning: Int, mature: Int) {
        let fetchDescriptor = FetchDescriptor<Card>()
        let allCards = try modelContext.fetch(fetchDescriptor)
        
        var newCount = 0
        var learningCount = 0
        var matureCount = 0
        
        for card in allCards {
            if card.timesReviewed == 0 {
                newCount += 1
            } else if card.interval >= 21 {
                matureCount += 1
            } else {
                learningCount += 1
            }
        }
        
        return (newCount, learningCount, matureCount)
    }
}
