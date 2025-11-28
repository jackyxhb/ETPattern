//
//  SessionStatsView.swift
//  ETPattern
//
//  Created by admin on 29/11/2025.
//

import SwiftUI
import CoreData

struct SessionStatsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \StudySession.date, ascending: false)],
        animation: .default)
    private var studySessions: FetchedResults<StudySession>

    var body: some View {
        NavigationView {
            List {
                if studySessions.isEmpty {
                    Text("No study sessions yet")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(studySessions) { session in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(session.date ?? Date(), style: .date)
                                    .font(.headline)
                                Spacer()
                                Text(session.date ?? Date(), style: .time)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            HStack(spacing: 16) {
                                VStack(alignment: .leading) {
                                    Text("Cards Reviewed")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(session.cardsReviewed)")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                }

                                VStack(alignment: .leading) {
                                    Text("Correct")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(session.correctCount)")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.green)
                                }

                                VStack(alignment: .leading) {
                                    Text("Accuracy")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(accuracyText(for: session))
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(accuracyColor(for: session))
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .onDelete(perform: deleteSessions)
                }
            }
            .navigationTitle("Study Sessions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
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
        guard reviewed > 0 else { return .secondary }
        let accuracy = Double(session.correctCount) / Double(reviewed)

        if accuracy >= 0.8 {
            return .green
        } else if accuracy >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }

    private func deleteSessions(offsets: IndexSet) {
        withAnimation {
            offsets.map { studySessions[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Handle error
                print("Error deleting sessions: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext

    // Create some sample sessions
    let session1 = StudySession(context: context)
    session1.date = Date()
    session1.cardsReviewed = 10
    session1.correctCount = 8

    let session2 = StudySession(context: context)
    session2.date = Date().addingTimeInterval(-86400) // Yesterday
    session2.cardsReviewed = 15
    session2.correctCount = 12

    let session3 = StudySession(context: context)
    session3.date = Date().addingTimeInterval(-172800) // 2 days ago
    session3.cardsReviewed = 8
    session3.correctCount = 5

    try? context.save()

    return SessionStatsView()
        .environment(\.managedObjectContext, context)
}