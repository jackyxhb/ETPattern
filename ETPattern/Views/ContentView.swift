//
//  ContentView.swift
//  ETPattern
//
//  Created by admin on 25/11/2025.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var ttsService: TTSService

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CardSet.createdDate, ascending: false)],
        animation: .default)
    private var cardSets: FetchedResults<CardSet>

    @State private var showingImportView = false
    @State private var selectedCardSet: CardSet?
    @State private var selectedTab = 0  // 0: Browse, 1: Study, 2: Auto

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ZStack {
                    DesignSystem.Gradients.background
                        .ignoresSafeArea()

                    VStack {
                        header
                        deckList(navigationValue: { cardSet in
                            self.selectedCardSet = cardSet
                            return .deck(cardSet)
                        })
                    }
                }
                .navigationBarHidden(true)
                .sheet(isPresented: $showingImportView) {
                    ImportView()
                        .environment(\.managedObjectContext, viewContext)
                }
                .navigationDestination(for: AppNavigation.self) { navigation in
                    switch navigation {
                    case .deck(let cardSet):
                        DeckDetailView(cardSet: cardSet, onStudy: {
                            self.selectedCardSet = cardSet
                            self.selectedTab = 1
                        }, onAuto: {
                            self.selectedCardSet = cardSet
                            self.selectedTab = 2
                        })
                            .environment(\.managedObjectContext, viewContext)
                            .environmentObject(ttsService)
                    case .study(let cardSet):
                        StudyView(cardSet: cardSet)
                            .environment(\.managedObjectContext, viewContext)
                            .environmentObject(ttsService)
                    case .auto(let cardSet):
                        AutoPlayView(cardSet: cardSet)
                            .environment(\.managedObjectContext, viewContext)
                            .environmentObject(ttsService)
                    case .browse:
                        EmptyView()
                    }
                }
            }
            .tabItem {
                Label("Browse", systemImage: "magnifyingglass")
            }
            .tag(0)

            Group {
                if let cardSet = selectedCardSet {
                    StudyView(cardSet: cardSet)
                        .environment(\.managedObjectContext, viewContext)
                        .environmentObject(ttsService)
                } else {
                    ZStack {
                        DesignSystem.Gradients.background
                            .ignoresSafeArea()
                        VStack {
                            Spacer()
                            Text("Select a deck from Browse tab")
                                .font(.title)
                                .foregroundColor(.white)
                            Spacer()
                        }
                    }
                }
            }
            .tabItem {
                Label("Study", systemImage: "book")
            }
            .tag(1)

            Group {
                if let cardSet = selectedCardSet {
                    AutoPlayView(cardSet: cardSet)
                        .environment(\.managedObjectContext, viewContext)
                        .environmentObject(ttsService)
                } else {
                    ZStack {
                        DesignSystem.Gradients.background
                            .ignoresSafeArea()
                        VStack {
                            Spacer()
                            Text("Select a deck from Browse tab")
                                .font(.title)
                                .foregroundColor(.white)
                            Spacer()
                        }
                    }
                }
            }
            .tabItem {
                Label("Auto", systemImage: "play.circle")
            }
            .tag(2)
        }
    }

    private var header: some View {
        HStack {
            Text("English Thought")
                .font(.largeTitle.bold())
                .foregroundColor(.white)

            Spacer()

            Button(action: { showingImportView = true }) {
                Image(systemName: "square.and.arrow.down")
                    .font(.title2)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal)
        .padding(.top, 60)
        .padding(.bottom, 20)
    }

    private func deckList(navigationValue: @escaping (CardSet) -> AppNavigation) -> some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(cardSets) { cardSet in
                    NavigationLink(value: navigationValue(cardSet)) {
                        DeckCard(cardSet: cardSet, onStudy: {
                            self.selectedCardSet = cardSet
                            self.selectedTab = 1
                        })
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct DeckCard: View {
    let cardSet: CardSet
    let onStudy: () -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DesignSystem.Metrics.cornerRadius)
                .fill(DesignSystem.Gradients.card)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.Metrics.cornerRadius)
                        .stroke(DesignSystem.Colors.stroke, lineWidth: 1.5)
                )
                .shadow(color: DesignSystem.Metrics.shadow, radius: 20, x: 0, y: 20)

            VStack(alignment: .leading, spacing: 12) {
                Text(cardSet.name ?? "Unnamed Deck")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .lineLimit(1)

                HStack {
                    Text("\(cardSet.cards?.count ?? 0) cards")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))

                    Spacer()

                    Button(action: onStudy) {
                        Text("Study")
                            .font(.headline)
                            .foregroundColor(DesignSystem.Colors.highlight)
                    }
                    .accessibilityIdentifier("Study")
                }
            }
            .padding(20)
        }
        .frame(height: 120)
        .accessibilityIdentifier("DeckCard")
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(TTSService())
}