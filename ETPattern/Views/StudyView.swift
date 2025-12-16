//
//  StudyView.swift
//  ETPattern
//
//  Created by admin on 25/11/2025.
//

import SwiftUI
import CoreData
import UIKit

struct StudyView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var ttsService: TTSService

    let cardSet: CardSet

    @StateObject private var sessionManager: SessionManager

    init(cardSet: CardSet) {
        self.cardSet = cardSet
        _sessionManager = StateObject(wrappedValue: SessionManager(viewContext: PersistenceController.shared.container.viewContext, cardSet: cardSet))
    }

    var body: some View {
        ZStack {
            DesignSystem.Gradients.background
                .ignoresSafeArea()

            VStack(spacing: 32) {
                header

                if sessionManager.showSessionComplete {
                    completionView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if sessionManager.cardsDue.isEmpty {
                    emptyState
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    studySessionContent
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .safeAreaInset(edge: .bottom) {
                if !sessionManager.showSessionComplete && !sessionManager.cardsDue.isEmpty {
                    SessionControlsView(sessionManager: sessionManager, closeAction: { dismiss() })
                }
            }
        }
        .onAppear {
            sessionManager.setTTSService(ttsService)
            Task {
                await sessionManager.loadOrCreateSession()
            }
        }
        .onDisappear {
            Task {
                await sessionManager.closeSession()
            }
        }
        .navigationTitle("Study Session")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(cardSet.name ?? "Study Session")
                .font(.title.bold())
                .foregroundColor(.white)
            Text("Spaced repetition learning")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
    }

    private var studySessionContent: some View {
        VStack(spacing: 12) {
            StudyProgressView(sessionManager: sessionManager)

            if sessionManager.currentCardIndex < sessionManager.cardsDue.count {
                CardDisplayView(sessionManager: sessionManager)
            }
        }
    }

    private var completionView: some View {
        VStack(spacing: 24) {
            Text("Session Complete")
                .font(.largeTitle.bold())
                .foregroundColor(.white)

            VStack(spacing: 18) {
                CompletionRow(title: "Cards Reviewed", value: "\(sessionManager.studySession?.cardsReviewed ?? 0)")
                CompletionRow(title: "Correct Answers", value: "\(sessionManager.studySession?.correctCount ?? 0)")
                CompletionRow(title: "Accuracy", value: sessionManager.accuracyText)
                if let duration = sessionManager.sessionDuration {
                    CompletionRow(title: "Time Spent", value: duration)
                }
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))

            Button(action: { dismiss() }) {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(DesignSystem.Gradients.accent)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 60)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.largeTitle)
                .foregroundColor(.white.opacity(0.7))
            Text("No cards due for review")
                .font(.title2.weight(.semibold))
                .foregroundColor(.white)
            Button("Done") {
                dismiss()
            }
            .font(.headline)
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .foregroundColor(.white)
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private struct CompletionRow: View {
        let title: String
        let value: String

        var body: some View {
            HStack {
                Text(title)
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Text(value)
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
            }
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let cardSet = CardSet(context: context)
    cardSet.name = "Sample Deck"

    let card = Card(context: context)
    card.front = "I think..."
    card.back = "Example 1<br>Example 2<br>Example 3<br>Example 4<br>Example 5"
    card.cardSet = cardSet

    return NavigationView {
        StudyView(cardSet: cardSet)
            .environment(\.managedObjectContext, context)
            .environmentObject(TTSService())
    }
}