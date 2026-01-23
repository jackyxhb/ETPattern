import SwiftUI
import SwiftData
#if os(iOS)
import UIKit
#endif
import ETPatternModels
import ETPatternServices

struct AutoPlayView: View {
    @Environment(\.theme) var theme
    @EnvironmentObject private var ttsService: TTSService
    
    @State private var viewModel: AutoPlayViewModel
    
    init(viewModel: AutoPlayViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            theme.gradients.background
                .ignoresSafeArea()

            VStack(spacing: theme.metrics.autoPlayViewSpacing) {
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
                        totalCards: viewModel.sessionCardIDs.count,
                        cardId: (viewModel.currentCard?.id).flatMap { Int($0) },
                        showSwipeFeedback: false,
                        swipeDirection: nil,
                        theme: theme
                    )
                }
            }
            .padding(.horizontal, theme.metrics.autoPlayViewHorizontalPadding)
            .safeAreaInset(edge: .bottom) {
                bottomControlBar
            }
        }
        .onAppear {
            viewModel.setTTSService(ttsService)
            Task {
                await viewModel.onAppear()
            }
        }
        .onDisappear {
            viewModel.onDisappear()
        }
    }

    private var header: some View {
        SharedHeaderView(
            // Accessing cardSet via currentCard or we could expose name in ViewModel
             title: viewModel.currentCard?.cardSet?.name ?? "Auto Play",
            subtitle: "Automatic playback",
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
                #if os(iOS)
                UIImpactFeedbackGenerator.lightImpact()
                #endif
                viewModel.cycleStrategy()
            },
            previousAction: {
                #if os(iOS)
                UIImpactFeedbackGenerator.lightImpact()
                #endif
                viewModel.manualPrevious()
            },
            nextAction: {
                #if os(iOS)
                UIImpactFeedbackGenerator.lightImpact()
                #endif
                viewModel.manualNext()
            },
            closeAction: {
                #if os(iOS)
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
            nextHint: "Skip to next card"
        ) {
            playPauseButton
        }
    }

    private var playPauseButton: some View {
        Button(action: {
            #if os(iOS)
            UIImpactFeedbackGenerator.mediumImpact()
            #endif
            viewModel.togglePlayback()
        }) {
            Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                .font(theme.metrics.title)
                .foregroundColor(theme.colors.textPrimary)
                .frame(width: theme.metrics.autoPlayButtonSize, height: theme.metrics.autoPlayButtonSize)
                .background(theme.gradients.accent)
                .clipShape(Circle())
                .shadow(color: theme.colors.highlight.opacity(0.3), radius: theme.metrics.autoPlayButtonShadowRadius, x: 0, y: theme.metrics.autoPlayButtonShadowY)
        }
        .accessibilityLabel(viewModel.isPlaying ? "Pause" : "Play")
    }
}
