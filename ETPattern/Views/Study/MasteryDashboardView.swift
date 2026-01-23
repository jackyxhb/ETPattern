import SwiftUI
import Charts
import Combine
import SwiftData

struct MasteryDashboardView: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: MasteryViewModel

    init(modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: MasteryViewModel(modelContext: modelContext))
    }

    var body: some View {
        ZStack {
            theme.gradients.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                
                ScrollView {
                    VStack(spacing: theme.metrics.largeSpacing) {
                        retentionCard
                        activityCard
                        maturityCard
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            viewModel.loadData()
        }
    }

    private var header: some View {
        HStack {
            Text("Mastery Dashboard")
                .font(theme.metrics.title2.bold())
                .foregroundColor(theme.colors.textPrimary)
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(theme.colors.textSecondary)
            }
        }
        .padding()
        .themedGlassBackground()
    }

    private var retentionCard: some View {
        DashboardCard(title: "Retention Rate", value: String(format: "%.1f%%", viewModel.retentionRate)) {
            Chart {
                ForEach(viewModel.dailyActivity.sorted(by: { $0.key < $1.key }), id: \.key) { date, count in
                    LineMark(
                        x: .value("Date", date),
                        y: .value("Reviews", count)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(theme.gradients.accent)
                }
            }
            .frame(height: 150)
        }
    }

    private var activityCard: some View {
        DashboardCard(title: "Daily Activity", value: "\(viewModel.totalReviews) reviews") {
            Chart {
                ForEach(viewModel.dailyActivity.sorted(by: { $0.key < $1.key }), id: \.key) { date, count in
                    BarMark(
                        x: .value("Date", date),
                        y: .value("Count", count)
                    )
                    .foregroundStyle(theme.gradients.success)
                    .cornerRadius(theme.metrics.chartBarCornerRadius)
                }
            }
            .frame(height: 150)
        }
    }

    private var maturityCard: some View {
        DashboardCard(title: "Deck Maturity", value: "\(viewModel.totalCards) cards") {
            HStack(spacing: theme.metrics.cardPadding) {
                MaturityStat(label: "New", count: viewModel.maturity.new, color: theme.colors.textSecondary)
                MaturityStat(label: "Learning", count: viewModel.maturity.learning, color: theme.colors.highlight)
                MaturityStat(label: "Mature", count: viewModel.maturity.mature, color: theme.colors.success)
            }
            .frame(maxWidth: .infinity)
            .padding(.top)
        }
    }
}

private struct DashboardCard<Content: View>: View {
    let title: String
    let value: String
    @ViewBuilder let content: () -> Content
    @Environment(\.theme) var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.metrics.deckDetailCardSpacing) {
            HStack {
                Text(title)
                    .font(theme.metrics.headline)
                    .foregroundColor(theme.colors.textSecondary)
                Spacer()
                Text(value)
                    .font(theme.metrics.title3.bold())
                    .foregroundColor(theme.colors.textPrimary)
            }
            
            content()
        }
        .padding()
        .background(theme.colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: theme.metrics.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: theme.metrics.cornerRadius, style: .continuous)
                .stroke(theme.colors.outline, lineWidth: 1)
        )
    }
}

private struct MaturityStat: View {
    let label: String
    let count: Int
    let color: Color
    @Environment(\.theme) var theme

    var body: some View {
        VStack {
            Text("\(count)")
                .font(theme.metrics.title2.bold())
                .foregroundColor(color)
            Text(label)
                .font(theme.metrics.caption)
                .foregroundColor(theme.colors.textSecondary)
        }
    }
}

@MainActor
class MasteryViewModel: ObservableObject {
    @Published var retentionRate: Double = 0
    @Published var dailyActivity: [Date: Int] = [:]
    @Published var totalReviews: Int = 0
    @Published var totalCards: Int = 0
    @Published var maturity: (new: Int, learning: Int, mature: Int) = (0, 0, 0)
    
    private let analyticsService: AnalyticsService

    init(modelContext: ModelContext) {
        self.analyticsService = AnalyticsService(modelContext: modelContext)
    }

    func loadData() {
        Task {
            do {
                let logs = try await analyticsService.fetchReviewLogs()
                self.dailyActivity = analyticsService.aggregateDailyActivity(logs: logs)
                self.retentionRate = analyticsService.calculateRetentionRate(logs: logs)
                self.totalReviews = logs.count
                
                let dist = try await analyticsService.getMaturityDistribution()
                self.maturity = dist
                self.totalCards = dist.new + dist.learning + dist.mature
            } catch {
                print("Error loading analytics: \(error)")
            }
        }
    }
}
