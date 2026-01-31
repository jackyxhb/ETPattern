//
//  StudyView.swift
//  ETPattern
//
//  Created by admin on 28/01/2026.
//

import SwiftUI
import SwiftData

struct StudyView: View {
    let cardSet: CardSet
    
    // Dependencies provided via Environment or Init
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.modelContext) private var modelContext
    @Environment(\.theme) var theme
    
    // ViewModel state
    @State private var viewModel: StudyViewModel?
    
    var body: some View {
        ZStack {
            // Background
            theme.gradients.background
                .ignoresSafeArea()
            
            if let viewModel {
                VStack(spacing: theme.metrics.autoPlayViewSpacing) {
                    // Header
                    HStack {
                        VStack(alignment: .leading) {
                            Text(cardSet.name)
                                .font(theme.metrics.title2.bold())
                                .foregroundStyle(.primary)
                            Text("Session Progress: \(viewModel.sessionProgress)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, theme.metrics.autoPlayViewHorizontalPadding)
                    
                    Spacer(minLength: 0)
                    
                    // Card Area
                    if let card = viewModel.currentCard {
                        LiquidCard(
                            front: card.front,
                            back: card.back,
                            cardID: card.id,
                            groupName: card.groupName,
                            isFlipped: viewModel.isFlipped,
                            totalCards: viewModel.cards.count,
                            onTap: {
                                viewModel.flip()
                            }
                        )
                        .transition(.scale.combined(with: .opacity))
                        .id(card.id)
                        
                    } else if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // ... empty state ...
                        VStack(spacing: theme.metrics.emptyStateTextSpacing) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: theme.metrics.emptyStateIconSize))
                                .foregroundStyle(.green)
                            Text("Session Complete!")
                                .font(.title2.bold())
                            Button("Close") {
                                viewModel.close()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .liquidGlass()
                        .padding(theme.metrics.contentHorizontalPadding)
                    }
                    
                    if viewModel.isFlipped {
                        LiquidControls { rating in
                            viewModel.rateCard(rating)
                        }
                        .padding(.horizontal, theme.metrics.cardFaceOuterPadding)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.vertical, theme.metrics.cardDisplayVerticalPadding)
                .safeAreaInset(edge: .bottom) {
                    SharedBottomControlBarView(
                        strategyToggleAction: {
                            UIImpactFeedbackGenerator.snap()
                            viewModel.cycleStrategy()
                        },
                        previousAction: {
                            UIImpactFeedbackGenerator.snap()
                            viewModel.previous()
                        },
                        nextAction: {
                            UIImpactFeedbackGenerator.snap()
                            viewModel.next()
                        },
                        closeAction: {
                            UIImpactFeedbackGenerator.snap()
                            viewModel.close()
                        },
                        isPreviousDisabled: viewModel.currentIndex == 0,
                        strategy: viewModel.currentStrategy,
                        currentPosition: viewModel.currentIndex + 1,
                        totalCards: viewModel.cards.count,
                        theme: theme,
                        previousHint: viewModel.currentIndex == 0 ? "No previous card available" : "Go to previous card",
                        nextHint: "Skip to next card"
                    ) {
                        // Empty middle content (no play/pause button for manual study)
                        EmptyView()
                    }
                }
            } else {
                ProgressView()
            }
        }
        .task {
            // Initialize ViewModel on load ensuring dependencies are ready
            if viewModel == nil {
                let service = SessionService(modelContext: modelContext)
                // TTSService is shared singleton, safe to use directly or inject
                let newVM = StudyViewModel(
                    cardSet: cardSet,
                    service: service,
                    ttsService: TTSService.shared,
                    coordinator: coordinator
                )
                self.viewModel = newVM
                await newVM.startSession()
            }
        }
    }
}

#Preview {
    // Preview container logic would go here
    Text("Study View Preview")
}
