//
//  DashboardView.swift
//  ETPattern
//
//  Created by admin on 28/01/2026.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @State private var viewModel: DashboardViewModel
    @Environment(\.theme) var theme
    
    init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ZStack {
            // Animated Background
            theme.gradients.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Hi there")
                                .font(.largeTitle.weight(.bold))
                                .foregroundStyle(.primary)
                        }
                        Spacer()
                        
                        Button {
                            viewModel.showSettings()
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                                .padding(12)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Bento Grid
                    Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                        // Row 1: Main Stats (2x2)
                        GridRow {
                            DailyProgressTile(
                                completed: viewModel.totalCardsReviewedToday,
                                goal: viewModel.dailyGoal
                            )
                            .frame(minHeight: 180)
                            .gridCellColumns(2) // Spans entire width
                        }
                        
                        // Row 2: Actions (1x1 + 1x1)
                        GridRow {
                            ActionTile(
                                icon: "bolt.fill",
                                title: "Quick Study",
                                subtitle: "Start Review",
                                color: .blue
                            ) {
                                viewModel.showQuickStudy()
                            }
                            
                            ActionTile(
                                icon: "plus.circle.fill",
                                title: "New Deck",
                                subtitle: "Create",
                                color: .green
                            ) {
                                Task {
                                    await viewModel.createDeck(name: "New Deck \(Date().formatted(date: .omitted, time: .shortened))")
                                }
                            }
                        }
                        .frame(height: 140)
                        
                        // Row 3: Deck List Header
                        GridRow {
                            HStack {
                                Text("Your Decks")
                                    .font(.headline)
                                Spacer()
                                Button("Import") {
                                    viewModel.showImport()
                                }
                                .font(.subheadline)
                            }
                            .padding(.top, 8)
                            .gridCellColumns(2)
                        }
                        
                        // Row 4+: Decks
                        // Note: Grid really wants static rows, but we can iterate.
                        // However, strictly, LazyStack inside GridRow is complex.
                        // For a pure Bento Grid, we usually have fixed slots.
                        // But for a list, we can use a ForEach producing GridRows.
                        ForEach(viewModel.decks) { deck in
                            GridRow {
                                DeckListTile(
                                    deck: deck,
                                    onOpen: { viewModel.openDeck(deck) },
                                    onAutoPlay: { viewModel.openAutoPlay(deck) },
                                    onDelete: { Task { await viewModel.deleteDeck(deck) } }
                                )
                                .gridCellColumns(2)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .task {
            await viewModel.loadData()
        }
    }
}

// MARK: - Sub-Tiles

struct DailyProgressTile: View {
    let completed: Int
    let goal: Int
    
    var percentage: Double {
        guard goal > 0 else { return 0 }
        return Double(completed) / Double(goal)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Daily Goal")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(completed)/\(goal)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.5)
                
                Text("Cards Reviewed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(.tertiary, lineWidth: 15)
                
                Circle()
                    .trim(from: 0, to: percentage)
                    .stroke(
                        AngularGradient(
                            colors: [.blue, .purple],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        style: StrokeStyle(lineWidth: 15, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring, value: percentage)
                
                VStack {
                    Text("\(Int(percentage * 100))%")
                        .font(.title2.bold())
                    Text("Done")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .bentoTileStyle()
    }
}

struct ActionTile: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button {
            // Feedback handled by sensoryFeedback or button style
            action()
        } label: {
            VStack(alignment: .leading) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundStyle(color)
                    .padding(12)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())
                
                Spacer()
                
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .bentoTileStyle()
        }
    }
}

struct DeckListTile: View {
    let deck: CardSet
    let onOpen: () -> Void
    let onAutoPlay: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Visible AutoPlay Button (Left Side)
            Button {
                // Feedback handled by sensoryFeedback or button style
                onAutoPlay()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "play.circle.fill")
                        .font(.title)
                    Text("Auto")
                        .font(.caption2.bold())
                }
                .foregroundStyle(.orange)
                .frame(width: 50)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading) {
                Text(deck.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text("\(deck.safeCards.count) cards")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                // Feedback handled by sensoryFeedback or button style
                onOpen()
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .bentoTileStyle()
        .contextMenu {
            Button(action: onAutoPlay) {
                Label("Auto Play", systemImage: "play.circle")
            }
            
            Button(role: .destructive, action: onDelete) {
                Label("Delete Deck", systemImage: "trash")
            }
        }
    }
}
