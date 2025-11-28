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

    let cardSet: CardSet

    @State private var currentCardIndex = 0
    @State private var cardsDue: [Card] = []
    @State private var studySession: StudySession?
    @State private var showSessionComplete = false
    @State private var sessionStartTime: Date?

    private let spacedRepetitionService = SpacedRepetitionService()
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)

    var body: some View {
        VStack {
            if cardsDue.isEmpty {
                Text("No cards due for review")
                    .font(.title2)
                    .foregroundColor(.secondary)
                Button("Done") {
                    dismiss()
                }
                .padding()
            } else if showSessionComplete {
                // Session complete view
                VStack(spacing: 20) {
                    Text("Session Complete!")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    VStack(spacing: 16) {
                        HStack {
                            Text("Cards Reviewed:")
                            Spacer()
                            Text("\(studySession?.cardsReviewed ?? 0)")
                                .fontWeight(.semibold)
                        }
                        
                        HStack {
                            Text("Correct Answers:")
                            Spacer()
                            Text("\(studySession?.correctCount ?? 0)")
                                .fontWeight(.semibold)
                        }
                        
                        HStack {
                            Text("Accuracy:")
                            Spacer()
                            Text(accuracyText)
                                .fontWeight(.semibold)
                        }
                        
                        if let duration = sessionDuration {
                            HStack {
                                Text("Time Spent:")
                                Spacer()
                                Text(duration)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    Button("Done") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top)
                }
                .padding()
            } else {
                // Study session view
                VStack {
                    // Session stats header
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Cards: \(currentCardIndex + 1) / \(cardsDue.count)")
                                .font(.headline)
                            if let accuracy = currentAccuracy, accuracy > 0 {
                                Text("Accuracy: \(Int(accuracy * 100))%")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        ProgressCircle(progress: progress)
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("\(studySession?.correctCount ?? 0) ✓")
                                .foregroundColor(.green)
                            Text("\((studySession?.cardsReviewed ?? 0) - (studySession?.correctCount ?? 0)) ✗")
                                .foregroundColor(.red)
                        }
                        .font(.caption)
                    }
                    .padding(.horizontal)

                    Spacer()

                    // Card display
                    if currentCardIndex < cardsDue.count {
                        VStack {
                            CardView(card: cardsDue[currentCardIndex], currentIndex: currentCardIndex, totalCards: cardsDue.count)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding()
                                .gesture(
                                    DragGesture()
                                        .onEnded { value in
                                            let horizontalAmount = value.translation.width
                                            let verticalAmount = value.translation.height
                                            
                                            // Only process horizontal swipes (more horizontal than vertical movement)
                                            if abs(horizontalAmount) > abs(verticalAmount) && abs(horizontalAmount) > 50 {
                                                feedbackGenerator.impactOccurred()
                                                if horizontalAmount > 0 {
                                                    // Swipe right = Easy
                                                    markAsEasy()
                                                } else {
                                                    // Swipe left = Again
                                                    markAsAgain()
                                                }
                                            }
                                        }
                                )
                            
                            // Swipe hint
                            Text("Swipe left for 'Again' • Swipe right for 'Easy'")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                    }

                    Spacer()

                    // Action buttons
                    HStack(spacing: 20) {
                        Button(action: markAsAgain) {
                            Text("Again")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }

                        Button(action: markAsEasy) {
                            Text("Easy")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle("Study Session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done") {
                    endStudySession()
                }
            }
        }
        .onAppear {
            loadCardsDue()
            startStudySession()
        }
    }

    private var progress: Double {
        guard !cardsDue.isEmpty else { return 0 }
        return Double(currentCardIndex) / Double(cardsDue.count)
    }

    private var currentAccuracy: Double? {
        guard let cardsReviewed = studySession?.cardsReviewed, cardsReviewed > 0 else { return nil }
        guard let correctCount = studySession?.correctCount else { return nil }
        return Double(correctCount) / Double(cardsReviewed)
    }

    private var accuracyText: String {
        guard let accuracy = currentAccuracy else { return "0%" }
        return "\(Int(accuracy * 100))%"
    }

    private var sessionDuration: String? {
        guard let startTime = sessionStartTime else { return nil }
        let duration = Date().timeIntervalSince(startTime)
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func loadCardsDue() {
        let now = Date()
        if let cards = cardSet.cards as? Set<Card> {
            cardsDue = Array(cards).filter { card in
                // Cards with no nextReviewDate (never reviewed) or past due dates are due
                card.nextReviewDate == nil || card.nextReviewDate! <= now
            }.sorted { (card1, card2) in
                // Sort by nextReviewDate, with nil dates (never reviewed) first
                let date1 = card1.nextReviewDate ?? Date.distantPast
                let date2 = card2.nextReviewDate ?? Date.distantPast
                return date1 < date2
            }
        }
    }

    private func startStudySession() {
        studySession = StudySession(context: viewContext)
        studySession?.date = Date()
        studySession?.cardsReviewed = 0
        studySession?.correctCount = 0
        sessionStartTime = Date()
    }

    private func markAsAgain() {
        guard currentCardIndex < cardsDue.count else { return }
        let card = cardsDue[currentCardIndex]

        card.recordReview(correct: false)
        spacedRepetitionService.updateCardDifficulty(card, rating: .again)
        studySession?.cardsReviewed += 1

        moveToNextCard()
    }

    private func markAsEasy() {
        guard currentCardIndex < cardsDue.count else { return }
        let card = cardsDue[currentCardIndex]

        card.recordReview(correct: true)
        spacedRepetitionService.updateCardDifficulty(card, rating: .easy)
        studySession?.cardsReviewed += 1
        studySession?.correctCount += 1

        moveToNextCard()
    }

    private func moveToNextCard() {
        currentCardIndex += 1

        if currentCardIndex >= cardsDue.count {
            endStudySession()
        }
    }

    private func endStudySession() {
        saveStudySession()
        showSessionComplete = true
    }

    private func saveStudySession() {
        try? viewContext.save()
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
    }
}