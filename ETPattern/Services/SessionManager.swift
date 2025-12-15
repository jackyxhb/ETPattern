//
//  SessionManager.swift
//  ETPattern
//
//  Created by admin on 15/12/2025.
//

import SwiftUI
import CoreData
import Combine

class SessionManager: ObservableObject {
    @Published var currentCardIndex = 0
    @Published var cardsDue: [Card] = []
    @Published var studySession: StudySession?
    @Published var showSessionComplete = false
    @Published var sessionStartTime: Date?
    @Published var isFlipped = false
    @Published var isRandomOrder = false
    @Published var swipeDirection: SwipeDirection? = nil
    @Published var showSwipeFeedback = false
    @Published var sessionCardList: [Card] = []
    @Published var cardsStudiedInSession: Int = 0

    private let viewContext: NSManagedObjectContext
    private let cardSet: CardSet
    private let spacedRepetitionService = SpacedRepetitionService()
    private var ttsService: TTSService?

    enum SwipeDirection {
        case left, right
    }

    init(viewContext: NSManagedObjectContext, cardSet: CardSet, ttsService: TTSService? = nil) {
        self.viewContext = viewContext
        self.cardSet = cardSet
        self.ttsService = ttsService
    }

    func setTTSService(_ service: TTSService) {
        self.ttsService = service
    }

    func loadOrCreateSession() async {
        isRandomOrder = UserDefaults.standard.string(forKey: "cardOrderMode") == "random"
        let fetchRequest: NSFetchRequest<StudySession> = StudySession.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "cardSet == %@ AND isActive == YES", cardSet)

        do {
            let existingSessions = try viewContext.fetch(fetchRequest)
            print("DEBUG: Found \(existingSessions.count) active sessions for cardSet '\(cardSet.name ?? "unnamed")'")
            if let existingSession = existingSessions.first {
                print("DEBUG: Resuming existing session")
                studySession = existingSession
                let remainingCards = existingSession.remainingCards as? Set<Card> ?? []
                cardsDue = sortCardsByDueDate(Array(remainingCards))

                if cardsDue.isEmpty {
                    await endStudySession()
                    return
                }

                createSessionList()
                cardsStudiedInSession = Int(existingSession.cardsReviewed)
                currentCardIndex = 0
                existingSession.currentCardIndex = 0
                sessionStartTime = Date()
            } else {
                print("DEBUG: Creating new session")
                createSessionList()
                cardsDue = sessionCardList
                cardsStudiedInSession = 0

                studySession = StudySession(context: viewContext)
                studySession?.date = Date()
                studySession?.cardsReviewed = 0
                studySession?.correctCount = 0
                studySession?.cardSet = cardSet
                studySession?.remainingCards = NSSet(array: cardsDue)
                studySession?.reviewedCards = NSSet()
                studySession?.currentCardIndex = 0
                studySession?.totalCards = Int32(sessionCardList.count)
                studySession?.isActive = true
                sessionStartTime = Date()
                print("DEBUG: Created new session with \(cardsDue.count) cards")
            }
        } catch {
            print("DEBUG: Error fetching sessions: \(error)")
            createSessionList()
            cardsDue = sessionCardList
            cardsStudiedInSession = 0
            studySession = StudySession(context: viewContext)
            studySession?.date = Date()
            studySession?.cardsReviewed = 0
            studySession?.correctCount = 0
            studySession?.cardSet = cardSet
            studySession?.remainingCards = NSSet(array: cardsDue)
            studySession?.reviewedCards = NSSet()
            studySession?.currentCardIndex = 0
            studySession?.totalCards = Int32(sessionCardList.count)
            studySession?.isActive = true
            sessionStartTime = Date()
            print("DEBUG: Created fallback session with \(cardsDue.count) cards")
        }
    }

    func markAsAgain() {
        guard currentCardIndex < cardsDue.count else { return }
        let card = cardsDue[currentCardIndex]

        card.recordReview(correct: false)
        spacedRepetitionService.updateCardDifficulty(card, rating: .again)
        studySession?.cardsReviewed += 1

        updateSessionRelationships(for: card)
        moveToNextCard()
    }

    func markAsEasy() {
        guard currentCardIndex < cardsDue.count else { return }
        let card = cardsDue[currentCardIndex]

        card.recordReview(correct: true)
        spacedRepetitionService.updateCardDifficulty(card, rating: .easy)
        studySession?.cardsReviewed += 1
        studySession?.correctCount += 1

        updateSessionRelationships(for: card)
        moveToNextCard()
    }

    func moveToNextCard() {
        cardsStudiedInSession += 1
        currentCardIndex += 1
        studySession?.currentCardIndex = Int32(currentCardIndex)
        isFlipped = false

        if currentCardIndex >= cardsDue.count {
            Task {
                await endStudySession()
            }
        }
    }

    func endStudySession() async {
        studySession?.isActive = false
        await saveStudySession()
        showSessionComplete = true
    }

    func closeSession() async {
        studySession?.isActive = false
        await saveStudySession()
    }

    func resetSession() async {
        if let session = studySession {
            viewContext.delete(session)
            do {
                try viewContext.save()
            } catch {
                print("DEBUG: Error saving after reset: \(error)")
            }
            cardsDue = []
            currentCardIndex = 0
            studySession = nil
            showSessionComplete = false
            sessionStartTime = nil
            isFlipped = false
            sessionCardList = []
            cardsStudiedInSession = 0
        }
    }

    func toggleOrderMode() {
        isRandomOrder.toggle()
        UserDefaults.standard.set(isRandomOrder ? "random" : "sequential", forKey: "cardOrderMode")
        applyOrderModePreservingCurrentCard()
    }

    func animateSwipe(direction: SwipeDirection) {
        swipeDirection = direction
        withAnimation(.easeInOut(duration: 0.3)) {
            showSwipeFeedback = true
            swipeOffset = direction == .right ? 300 : -300
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.showSwipeFeedback = false
                self.swipeDirection = nil
                self.swipeOffset = 0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if direction == .right {
                    self.markAsEasy()
                } else {
                    self.markAsAgain()
                }
            }
        }
    }

    func flipCard() {
        withAnimation(.bouncy) {
            isFlipped.toggle()
            speakCurrentText()
        }
    }

    func speakCurrentText() {
        guard currentCardIndex < cardsDue.count, let ttsService = ttsService else { return }
        let card = cardsDue[currentCardIndex]
        let textToSpeak = isFlipped ? formatBackText() : (card.front ?? "")
        ttsService.speak(textToSpeak)
    }

    func onCardChange() {
        isFlipped = false
        ttsService?.stop()
        speakCurrentText()
    }

    // MARK: - Computed Properties

    var progress: Double {
        guard sessionCardList.count > 0 else { return 0 }
        let currentPosition = (cardsStudiedInSession % sessionCardList.count) + 1
        return Double(currentPosition) / Double(sessionCardList.count)
    }

    var totalCardsInSession: Int {
        return Int(studySession?.totalCards ?? 0)
    }

    var cardsReviewedCount: Int {
        return Int(studySession?.cardsReviewed ?? 0)
    }

    var currentCardNumber: Int {
        guard totalCardsInSession > 0 else { return 0 }
        let nextNumber = cardsReviewedCount + 1
        return min(nextNumber, totalCardsInSession)
    }

    var cardsRemaining: Int {
        return max(totalCardsInSession - cardsReviewedCount, 0)
    }

    var currentAccuracy: Double? {
        guard let cardsReviewed = studySession?.cardsReviewed, cardsReviewed > 0 else { return nil }
        guard let correctCount = studySession?.correctCount else { return nil }
        return Double(correctCount) / Double(cardsReviewed)
    }

    var accuracyText: String {
        guard let accuracy = currentAccuracy else { return "0%" }
        return "\(Int(accuracy * 100))%"
    }

    var sessionDuration: String? {
        guard let startTime = sessionStartTime else { return nil }
        let duration = Date().timeIntervalSince(startTime)
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }

    @Published var swipeOffset: CGFloat = 0

    // MARK: - Private Methods

    private func createSessionList() {
        guard let setCards = cardSet.cards as? Set<Card> else {
            sessionCardList = []
            return
        }

        let sorted = setCards.sorted { ($0.front ?? "") < ($1.front ?? "") }
        if isRandomOrder {
            sessionCardList = sorted.shuffled()
        } else {
            sessionCardList = sorted
        }
    }

    private func updateSessionRelationships(for card: Card) {
        guard let session = studySession else { return }

        var reviewed = session.reviewedCards as? Set<Card> ?? Set()
        reviewed.insert(card)
        session.reviewedCards = reviewed as NSSet

        var remaining = session.remainingCards as? Set<Card> ?? Set()
        remaining.remove(card)
        session.remainingCards = remaining as NSSet
    }

    private func saveStudySession() async {
        do {
            try viewContext.save()
        } catch {
            print("DEBUG: Error saving study session: \(error)")
        }
    }

    private func sortCardsByDueDate(_ cards: [Card]) -> [Card] {
        return cards.sorted { card1, card2 in
            let date1 = card1.nextReviewDate ?? Date.distantPast
            let date2 = card2.nextReviewDate ?? Date.distantPast
            if date1 == date2 {
                return (card1.front ?? "") < (card2.front ?? "")
            }
            return date1 < date2
        }
    }

    private func applyOrderModePreservingCurrentCard() {
        let currentCard = cardsDue.isEmpty ? nil : cardsDue[currentCardIndex]

        createSessionList()

        let remainingCardIDs = Set(cardsDue.map { $0.objectID })
        cardsDue = sessionCardList.filter { remainingCardIDs.contains($0.objectID) }

        if let currentCard = currentCard,
           let newIndex = cardsDue.firstIndex(where: { $0.objectID == currentCard.objectID }) {
            currentCardIndex = newIndex
        } else {
            currentCardIndex = 0
            isFlipped = false
        }

        cardsStudiedInSession = Int(studySession?.cardsReviewed ?? 0)
    }

    private func formatBackText() -> String {
        guard let card = currentCardIndex < cardsDue.count ? cardsDue[currentCardIndex] : nil,
              let backText = card.back else {
            return "No back"
        }
        return backText.replacingOccurrences(of: "<br>", with: "\n")
    }
}