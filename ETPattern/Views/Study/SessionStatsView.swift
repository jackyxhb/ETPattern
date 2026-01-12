import SwiftUI
import SwiftData
import Charts
import ETPatternModels
import ETPatternServices

struct SessionStatsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) var theme

    @Query(sort: \StudySession.date, order: .reverse)
    private var studySessions: [StudySession]
    
    @State private var dailyActivity: [Date: Int] = [:]

    var body: some View {
        ZStack {
            theme.gradients.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                header
                
                ScrollView {
                    VStack(spacing: theme.metrics.largeSpacing) {
                        if !studySessions.isEmpty {
                            activitySection
                        }
                        
                        historySection
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            calculateActivity()
        }
    }

    private var header: some View {
        HStack {
            Text(NSLocalizedString("session_stats", comment: "Session statistics screen title"))
                .font(theme.metrics.headline)
                .foregroundColor(theme.colors.textPrimary)
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(theme.colors.textSecondary)
                    .font(.title2)
            }
        }
        .padding()

        .themedGlassBackground()
    }

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: theme.metrics.deckDetailCardSpacing) {
            Text("Activity (Last 7 Days)")
                .font(theme.metrics.subheadline.bold())
                .foregroundColor(theme.colors.textSecondary)
            
            Chart {
                ForEach(dailyActivity.sorted(by: { $0.key < $1.key }), id: \.key) { date, count in
                    BarMark(
                        x: .value("Day", date, unit: .day),
                        y: .value("Reviews", count)
                    )
                    .foregroundStyle(theme.gradients.accent)
                    .cornerRadius(theme.metrics.chartBarCornerRadius)
                }
            }
            .frame(height: 100)
            .padding(.top, 4)
        }
        .padding()
        .background(theme.colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: theme.metrics.cornerRadius, style: .continuous))
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: theme.metrics.mediumSpacing) {
            Text("Study History")
                .font(theme.metrics.subheadline.bold())
                .foregroundColor(theme.colors.textSecondary)
            
            if studySessions.isEmpty {
                Text("No study sessions yet")
                    .foregroundColor(theme.colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                ForEach(studySessions) { session in
                    sessionCard(session)
                }
            }
        }
    }

    private func sessionCard(_ session: StudySession) -> some View {
        VStack(alignment: .leading, spacing: theme.metrics.deckDetailCardSpacing) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.date, style: .date)
                        .font(theme.metrics.headline)
                        .foregroundColor(theme.colors.textPrimary)
                    Text(session.date, style: .time)
                        .font(theme.metrics.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
                Spacer()
                accuracyBadge(for: session)
            }

            HStack(spacing: theme.metrics.largeSpacing) {
                statView(label: "Reviewed", value: "\(session.cardsReviewed)")
                statView(label: "Correct", value: "\(session.correctCount)", color: theme.colors.success)
                statView(label: "Duration", value: durationText(for: session))
            }
        }
        .padding()
        .background(theme.colors.surfaceLight)
        .clipShape(RoundedRectangle(cornerRadius: theme.metrics.cornerRadius, style: .continuous))
    }

    private func statView(label: String, value: String, color: Color? = nil) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(theme.metrics.caption)
                .foregroundColor(theme.colors.textSecondary)
            Text(value)
                .font(theme.metrics.subheadline.bold())
                .foregroundColor(color ?? theme.colors.textPrimary)
        }
    }

    private func accuracyBadge(for session: StudySession) -> some View {
        let text = accuracyText(for: session)
        let color = accuracyColor(for: session)
        
        return Text(text)
            .font(.caption.bold())
            .padding(.horizontal, theme.metrics.standardSpacing)
            .padding(.vertical, theme.metrics.smallSpacing)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .clipShape(Capsule())
    }

    private func durationText(for session: StudySession) -> String {
        // Mock duration or use real if available. Assuming 5s per card if not recorded.
        let seconds = session.cardsReviewed * 5 
        if seconds < 60 { return "\(seconds)s" }
        return "\(seconds / 60)m"
    }

    private func calculateActivity() {
        let calendar = Calendar.current
        var activity: [Date: Int] = [:]
        
        for session in studySessions {
            let day = calendar.startOfDay(for: session.date)
            activity[day, default: 0] += Int(session.cardsReviewed)
        }
        
        self.dailyActivity = activity
    }

    private func accuracyText(for session: StudySession) -> String {
        let reviewed = session.cardsReviewed
        guard reviewed > 0 else { return "0%" }
        let accuracy = Double(session.correctCount) / Double(reviewed)
        return "\(Int(accuracy * 100))%"
    }

    private func accuracyColor(for session: StudySession) -> Color {
        let reviewed = session.cardsReviewed
        guard reviewed > 0 else { return theme.colors.textSecondary }
        let accuracy = Double(session.correctCount) / Double(reviewed)

        if accuracy >= 0.8 {
            return theme.colors.success
        } else if accuracy >= 0.6 {
            return theme.colors.warning
        } else {
            return theme.colors.danger
        }
    }
}

#Preview {
    SessionStatsView()
        .modelContainer(PersistenceController.preview.container)
        .environment(\.theme, Theme.dark)
}