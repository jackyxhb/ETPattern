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
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading) {
                            Text(cardSet.name)
                                .font(.title3.bold())
                                .foregroundStyle(.primary)
                            Text("Session Progress: \(viewModel.sessionProgress)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Card Area
                    if let card = viewModel.currentCard {
                        LiquidCard(
                            front: card.front,
                            back: card.back,
                            isFlipped: viewModel.isFlipped,
                            onTap: {
                                viewModel.flip()
                            }
                        )
                        .padding()
                        .transition(.scale.combined(with: .opacity))
                        .id(card.id)
                        
                    } else if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // Empty State (Session Complete or Empty Deck)
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 64))
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
                        .padding()
                    }
                    
                    // Rating Controls (only when flipped)
                    if viewModel.isFlipped {
                        LiquidControls { rating in
                            viewModel.rateCard(rating)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    SharedBottomControlBarView(
                        strategyToggleAction: {
                            // Strategy toggle not available in StudyView (uses fixed intelligent)
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
                        strategy: .intelligent,
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
