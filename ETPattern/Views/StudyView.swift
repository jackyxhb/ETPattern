//
//  StudyView.swift
//  ETPattern
//
//  Created by admin on 25/11/2025.
//

import SwiftUI
import CoreData

struct StudyView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let cardSet: CardSet

    @State private var currentCardIndex = 0
    @State private var cardsDue: [Card] = []
    @State private var studySession: StudySession?

    private let spacedRepetitionService = SpacedRepetitionService()

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
            } else {
                // Progress indicator
                HStack {
                    Text("\(currentCardIndex + 1) / \(cardsDue.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    ProgressView(value: Double(currentCardIndex + 1), total: Double(cardsDue.count))
                        .frame(width: 100)
                }
                .padding(.horizontal)

                Spacer()

                // Card display
                if currentCardIndex < cardsDue.count {
                    VStack {
                        CardView(card: cardsDue[currentCardIndex])
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding()
                            .gesture(
                                DragGesture()
                                    .onEnded { value in
                                        let horizontalAmount = value.translation.width
                                        let verticalAmount = value.translation.height
                                        
                                        // Only process horizontal swipes (more horizontal than vertical movement)
                                        if abs(horizontalAmount) > abs(verticalAmount) && abs(horizontalAmount) > 50 {
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
        .navigationTitle("Study Session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done") {
                    saveStudySession()
                    dismiss()
                }
            }
        }
        .onAppear {
            loadCardsDue()
            startStudySession()
        }
    }

    private func loadCardsDue() {
        cardsDue = spacedRepetitionService.getCardsDueForReview(from: cardSet)
        
        // If no cards are due, show all cards (for initial learning)
        if cardsDue.isEmpty {
            if let cards = cardSet.cards as? Set<Card> {
                cardsDue = Array(cards).shuffled()
            }
        }
    }

    private func startStudySession() {
        studySession = StudySession(context: viewContext)
        studySession?.date = Date()
        studySession?.cardsReviewed = 0
        studySession?.correctCount = 0
    }

    private func markAsAgain() {
        guard currentCardIndex < cardsDue.count else { return }
        let card = cardsDue[currentCardIndex]

        spacedRepetitionService.updateCardDifficulty(card, rating: .again)
        studySession?.cardsReviewed += 1

        moveToNextCard()
    }

    private func markAsEasy() {
        guard currentCardIndex < cardsDue.count else { return }
        let card = cardsDue[currentCardIndex]

        spacedRepetitionService.updateCardDifficulty(card, rating: .easy)
        studySession?.cardsReviewed += 1
        studySession?.correctCount += 1

        moveToNextCard()
    }

    private func moveToNextCard() {
        currentCardIndex += 1

        if currentCardIndex >= cardsDue.count {
            saveStudySession()
        }
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