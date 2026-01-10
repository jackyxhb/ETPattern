import SwiftUI
import SwiftData
import ETPatternModels

struct SessionStatsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) var theme

    @Query(sort: \StudySession.date, order: .reverse)
    private var studySessions: [StudySession]

    var body: some View {
        ZStack {
            theme.gradients.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom header for sheet presentation
                HStack {
                    Text(NSLocalizedString("session_stats", comment: "Session statistics screen title"))
                        .font(.headline)
                        .foregroundColor(theme.colors.textPrimary)
                        .dynamicTypeSize(.large ... .accessibility5)
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(theme.colors.textSecondary)
                            .font(.title2)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                
                Form {
                    // Historical Sessions Section
                    Section(header: Text("Study History")
                        .foregroundColor(theme.colors.textPrimary).dynamicTypeSize(.large ... .accessibility5)) {
                    if studySessions.isEmpty {
                        Text("No study sessions yet")
                            .foregroundColor(theme.colors.textSecondary)
                            .dynamicTypeSize(.large ... .accessibility5)
                            .padding(theme.metrics.buttonPadding)
                    } else {
                        ForEach(studySessions) { session in
                            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                                HStack {
                                    Text(session.date, style: .date)
                                        .font(theme.metrics.headline)
                                        .foregroundColor(theme.colors.textPrimary)
                                        .dynamicTypeSize(.large ... .accessibility5)
                                    Spacer()
                                    Text(session.date, style: .time)
                                        .font(theme.metrics.subheadline)
                                        .foregroundColor(theme.colors.textSecondary)
                                        .dynamicTypeSize(.large ... .accessibility5)
                                }

                                HStack(spacing: theme.metrics.largeSpacing) {
                                    VStack(alignment: .leading) {
                                        Text("Cards Reviewed")
                                            .font(theme.metrics.caption)
                                            .foregroundColor(theme.colors.textSecondary)
                                            .dynamicTypeSize(.large ... .accessibility5)
                                        Text("\(session.cardsReviewed)")
                                            .font(theme.metrics.title3.weight(.semibold))
                                            .foregroundColor(theme.colors.textPrimary)
                                            .dynamicTypeSize(.large ... .accessibility5)
                                    }

                                    VStack(alignment: .leading) {
                                        Text("Correct")
                                            .font(theme.metrics.caption)
                                            .foregroundColor(theme.colors.textSecondary)
                                            .dynamicTypeSize(.large ... .accessibility5)
                                        Text("\(session.correctCount)")
                                            .font(theme.metrics.title3.weight(.semibold))
                                            .foregroundColor(theme.colors.success)
                                            .dynamicTypeSize(.large ... .accessibility5)
                                    }

                                    VStack(alignment: .leading) {
                                        Text("Accuracy")
                                            .font(theme.metrics.caption)
                                            .foregroundColor(theme.colors.highlight.opacity(0.7))
                                            .dynamicTypeSize(.large ... .accessibility5)
                                        Text(accuracyText(for: session))
                                            .font(theme.metrics.title3.weight(.semibold))
                                            .foregroundColor(accuracyColor(for: session))
                                            .dynamicTypeSize(.large ... .accessibility5)
                                    }
                                }
                            }
                            .padding(.vertical, theme.metrics.standardSpacing)
                        }
                        .onDelete(perform: deleteSessions)
                    }
                }
                .listRowBackground(theme.colors.surfaceLight.opacity(0.5))
            }
            .scrollContentBackground(.hidden)
            }
        }
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

    private func deleteSessions(offsets: IndexSet) {
        withAnimation {
            offsets.map { studySessions[$0] }.forEach { session in
                modelContext.delete(session)
            }
        }
    }
}

#Preview {
    SessionStatsView()
        .modelContainer(PersistenceController.preview.container)
        .environment(\.theme, Theme.default)
}