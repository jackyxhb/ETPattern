import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#endif
import os.log
import ETPatternModels
import ETPatternServices
// import ETPatternViewModels // No need if in same module, otherwise need module name

struct StudyView: View {
    @Environment(\.theme) var theme
    @EnvironmentObject private var ttsService: TTSService
    
    // ViewModel injected via init
    // ViewModel injected via init
    @State private var viewModel: StudyViewModel
    
    private let logger = Logger(subsystem: "com.jack.ETPattern", category: "StudyView")
    
    @State private var showSwipeFeedback = false
    @State private var swipeDirection: SwipeDirection?
    @State private var isSwipeInProgress = false
    @State private var swipeTask: Task<Void, Never>?

    init(viewModel: StudyViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            theme.gradients.background
                .ignoresSafeArea()

            VStack(spacing: theme.metrics.studyViewSpacing) {
                header

                if viewModel.sessionCardIDs.isEmpty {
                    emptyState
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    SharedCardDisplayView(
                        frontText: viewModel.currentCard?.front ?? "Loading...",
                        backText: (viewModel.currentCard?.back ?? "").replacingOccurrences(of: "<br>", with: "\n"),
                        groupName: viewModel.currentCard?.groupName ?? "",
                        cardName: viewModel.currentCard?.cardName ?? "",
                        isFlipped: viewModel.isFlipped,
                        currentIndex: viewModel.currentIndex,
                        totalCards: viewModel.totalCardsCount,
                        cardId: (viewModel.currentCard?.id).flatMap { Int($0) },
                        showSwipeFeedback: showSwipeFeedback,
                        swipeDirection: swipeDirection,
                        theme: theme
                    )
                    .gesture(
                        DragGesture(minimumDistance: 50)
                            .onChanged { value in
                                if !isSwipeInProgress {
                                    let horizontalAmount = value.translation.width
                                    let verticalAmount = value.translation.height

                                    if abs(horizontalAmount) > abs(verticalAmount) && abs(horizontalAmount) > 30 {
                                        isSwipeInProgress = true
                                        swipeDirection = horizontalAmount > 0 ? .right : .left
                                        showSwipeFeedback = true
                                        #if canImport(UIKit)
                                        UIImpactFeedbackGenerator.lightImpact()
                                        #endif
                                    }
                                }
                            }
                            .onEnded { value in
                                if isSwipeInProgress {
                                    handleSwipe(swipeDirection!)
                                }
                                showSwipeFeedback = false
                                swipeDirection = nil
                                isSwipeInProgress = false
                            }
                    )
                    .onTapGesture {
                        #if canImport(UIKit)
                        UIImpactFeedbackGenerator.lightImpact()
                        #endif
                        viewModel.flipCard()
                        speakCurrentText()
                    }
                    .accessibilityAction(named: "Flip Card") {
                        #if canImport(UIKit)
                        UIImpactFeedbackGenerator.lightImpact()
                        #endif
                        viewModel.flipCard()
                        speakCurrentText()
                    }
                    .accessibilityAction(named: "Mark as Easy") {
                        handleRating(.easy)
                    }
                    .accessibilityAction(named: "Mark as Again") {
                        handleRating(.again)
                    }
                }
            }
            .padding(.horizontal, theme.metrics.studyViewHorizontalPadding)
            .safeAreaInset(edge: .bottom) {
                if viewModel.isFlipped {
                    ratingToolbar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    bottomControlBar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("English Pattern Study Session")
        .dynamicTypeSize(.large ... .accessibility5)
        .task {
            await viewModel.onAppear()
            // Auto-speak first card if needed? Or wait for interaction.
            // Old logic didn't auto-speak on appear, only on flip/navigation.
        }
        .onDisappear {
            viewModel.onDisappear()
            ttsService.stop()
        }
        .onChange(of: viewModel.currentIndex) { _, _ in
            ttsService.stop()
            speakCurrentText()
            #if canImport(UIKit)
            UIAccessibility.post(notification: .announcement, argument: "Now showing card \(viewModel.currentIndex + 1)")
            #endif
        }
        .onChange(of: viewModel.isFlipped) { _, flipped in
            if flipped { speakCurrentText() }
        }
    }

    private var header: some View {
        SharedHeaderView(
            // Accessing cardSet via currentCard or we could expose name in ViewModel
             title: viewModel.currentCard?.cardSet?.name ?? "Study",
            subtitle: "Spaced repetition learning",
            theme: theme
        )
    }

    private var emptyState: some View {
        SharedEmptyStateView(
            title: NSLocalizedString("no_cards_title", comment: "Title for empty cards state"),
            subtitle: NSLocalizedString("no_cards_subtitle", comment: "Subtitle for empty cards state"),
            description: NSLocalizedString("no_cards_description", comment: "Description for empty cards state"),
            icon: "waveform",
            iconColor: theme.colors.textSecondary,
            theme: theme
        )
    }

    private var bottomControlBar: some View {
        SharedBottomControlBarView(
            strategyToggleAction: {
                #if canImport(UIKit)
                UIImpactFeedbackGenerator.lightImpact()
                #endif
                viewModel.cycleStrategy()
            },
            previousAction: {
                #if canImport(UIKit)
                UIImpactFeedbackGenerator.lightImpact()
                #endif
                viewModel.moveToPrevious()
            },
            nextAction: {
                #if canImport(UIKit)
                UIImpactFeedbackGenerator.lightImpact()
                #endif
                viewModel.moveToNext()
            },
            closeAction: {
                #if canImport(UIKit)
                UIImpactFeedbackGenerator.lightImpact()
                #endif
                viewModel.dismiss()
            },
            isPreviousDisabled: viewModel.currentIndex == 0,
            strategy: viewModel.studyStrategy,
            currentPosition: viewModel.sessionCardIDs.count > 0 ? viewModel.currentIndex + 1 : 0,
            totalCards: viewModel.sessionCardIDs.count,
            theme: theme,
            previousHint: viewModel.currentIndex == 0 ? "No previous card available" : "Go to previous card",
            nextHint: "Go to next card"
        ) {
            speakCurrentButton
        }
    }

    private var speakCurrentButton: some View {
        Button(action: {
            #if canImport(UIKit)
            UIImpactFeedbackGenerator.lightImpact()
            #endif
            speakCurrentText()
        }) {
            Image(systemName: ttsService.isSpeaking ? "speaker.wave.2.fill" : "speaker.wave.2")
                .font(theme.metrics.title3)
                .foregroundColor(theme.colors.textPrimary)
                .frame(width: theme.metrics.studySpeakButtonSize, height: theme.metrics.studySpeakButtonSize)
                .background(ttsService.isSpeaking ? theme.gradients.danger : theme.gradients.success)
                .clipShape(Circle())
        }
        .accessibilityLabel(ttsService.isSpeaking ? "Stop speaking" : "Speak current card")
    }

    private func speakCurrentText() {
        guard let currentCard = viewModel.currentCard else { return }
        let text = viewModel.isFlipped ?
            currentCard.back.replacingOccurrences(of: "<br>", with: "\n") :
            currentCard.front
        ttsService.speak(text)
    }

    private var ratingToolbar: some View {
        HStack(spacing: theme.metrics.actionBarButtonSpacing) {
            RatingButton(title: "Again", color: theme.colors.danger, action: { handleRating(.again) })
            RatingButton(title: "Hard", color: theme.colors.warning, action: { handleRating(.hard) })
            RatingButton(title: "Good", color: theme.colors.success, action: { handleRating(.good) })
            RatingButton(title: "Easy", color: theme.colors.highlight, action: { handleRating(.easy) })
        }
        .padding(.horizontal, theme.metrics.actionBarHorizontalPadding)
        .padding(.vertical, theme.metrics.actionBarVerticalPadding)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: theme.metrics.actionBarCornerRadius, style: .continuous))
        .padding(.horizontal, theme.metrics.actionBarContainerHorizontalPadding)
    }

    private struct RatingButton: View {
        let title: String
        let color: Color
        let action: () -> Void
        @Environment(\.theme) var theme

        var body: some View {
            Button(action: action) {
                Text(title)
                    .font(theme.metrics.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, theme.metrics.actionButtonVerticalPadding)
                    .background(color.opacity(0.8))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: theme.metrics.actionButtonCornerRadius, style: .continuous))
            }
        }
    }

    private func handleRating(_ rating: DifficultyRating) {
        // Cancel any existing swipe task
        swipeTask?.cancel()

        // Provide haptic feedback
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: rating == .again ? .heavy : .medium)
        generator.impactOccurred()
        #endif
        
        // Notify ViewModel
        viewModel.handleRating(rating)

        // Animation handled by ViewModel state changes? 
        // ViewModel updates currentIndex immediately. 
        // We might want to delay standard transition logic in VM or here.
        // For MVVM, VM should drive state.
        // If we want delay for visual feedback, we can do it here before calling VM or VM handles it.
        // Old logic had delay. Let's keep delay here for UI polish if desired, or assume VM handles it.
        // In the updated VM, `handleRating` calls `moveToNext`.
        // To keep the 'swipe task' delay logic:
        /*
        swipeTask = Task {
             try? await Task.sleep(for: .milliseconds(400))
             await MainActor.run { viewModel.handleRating(rating) }
        }
        */
        // But VM `handleRating` is async-capable. 
        // For now, calling it directly for responsiveness.
    }

    private func handleSwipe(_ direction: SwipeDirection) {
        if viewModel.isFlipped {
            handleRating(direction == .right ? .good : .again)
        } else {
            viewModel.flipCard()
            speakCurrentText()
        }
    }
}

#Preview {
    NavigationView {
        StudyView(viewModel: StudyViewModel(
            cardSet: previewCardSet,
            modelContext: PersistenceController.preview.container.mainContext,
            service: StudyService(modelContainer: PersistenceController.preview.container),
            coordinator: nil
        ))
        .modelContainer(PersistenceController.preview.container)
        .environmentObject(TTSService.shared)
    }
}

@MainActor
private var previewCardSet: CardSet {
    let container = PersistenceController.preview.container
    let cardSet = CardSet(name: "Sample Deck")
    container.mainContext.insert(cardSet)

    let card = Card(id: 1, front: "I think...", back: "Example 1<br>Example 2<br>Example 3<br>Example 4<br>Example 5", cardName: "Pattern", groupId: 1, groupName: "Group 1")
    card.cardSet = cardSet
    cardSet.cards.append(card)
    container.mainContext.insert(card)
    
    return cardSet
}
