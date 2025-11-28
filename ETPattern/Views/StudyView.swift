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
    @State private var isShowingFront = true
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
                    CardView(card: cardsDue[currentCardIndex], isShowingFront: $isShowingFront)
                        .frame(maxWidth: .infinity, maxHeight: 400)
                        .padding()
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
        if let cards = cardSet.cards as? Set<Card> {
            cardsDue = Array(cards).filter { card in
                // For now, include all cards. Later we'll filter by nextReviewDate
                return true
            }.shuffled()
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
        isShowingFront = true
        currentCardIndex += 1

        if currentCardIndex >= cardsDue.count {
            saveStudySession()
        }
    }

    private func saveStudySession() {
        try? viewContext.save()
    }
}

struct CardView: View {
    let card: Card
    @Binding var isShowingFront: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(radius: 5)

            VStack {
                Spacer()

                if isShowingFront {
                    Text(card.front ?? "No front")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    VStack(spacing: 16) {
                        Text(card.front ?? "No front")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        Text(card.back ?? "No back")
                            .font(.body)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }

                Spacer()

                Text(isShowingFront ? "Tap to reveal" : "Tap to flip back")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 300)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                isShowingFront.toggle()
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
    }
}