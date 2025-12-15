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
    @State private var showingSettings = false

    var body: some View {
        NavigationView {
            ZStack {
                DesignSystem.Gradients.background
                    .ignoresSafeArea()

                VStack {
                    header
                    deckList
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingImportView) {
                ImportView()
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }

    private var header: some View {
        HStack {
            Text("English Thought")
                .font(.largeTitle.bold())
                .foregroundColor(.white)

            Spacer()

            HStack(spacing: 16) {
                Button(action: { showingImportView = true }) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.title2)
                        .foregroundColor(.white)
                }

                Button(action: { showingSettings = true }) {
                    Image(systemName: "gear")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 60)
        .padding(.bottom, 20)
    }

    private var deckList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(cardSets) { cardSet in
                    DeckCard(cardSet: cardSet)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct DeckCard: View {
    let cardSet: CardSet
    @State private var navigateToDetail = false

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

                    Button(action: { navigateToDetail = true }) {
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
        .background(
            NavigationLink(destination: DeckDetailView(cardSet: cardSet), isActive: $navigateToDetail) {
                EmptyView()
            }
            .hidden()
        )
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(TTSService())
}