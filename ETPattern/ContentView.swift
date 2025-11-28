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

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CardSet.createdDate, ascending: false)],
        animation: .default)
    private var cardSets: FetchedResults<CardSet>

    var body: some View {
        NavigationView {
            List {
                ForEach(cardSets) { cardSet in
                    NavigationLink {
                        DeckDetailView(cardSet: cardSet)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(cardSet.name ?? "Unnamed Deck")
                                .font(.headline)
                            Text("Created: \(cardSet.createdDate ?? Date(), formatter: dateFormatter)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            if let cards = cardSet.cards as? Set<Card> {
                                Text("\(cards.count) cards")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .onDelete(perform: deleteCardSets)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        NavigationLink(destination: SessionStatsView()) {
                            Image(systemName: "chart.bar")
                                .imageScale(.large)
                        }
                        NavigationLink(destination: ImportView()) {
                            Image(systemName: "square.and.arrow.down")
                                .imageScale(.large)
                        }
                        NavigationLink(destination: SettingsView()) {
                            Image(systemName: "gear")
                                .imageScale(.large)
                        }
                    }
                }
                ToolbarItem {
                    Button(action: addCardSet) {
                        Label("Add Deck", systemImage: "plus")
                    }
                }
            }
            Text("Select a deck")
        }
        .navigationTitle("Flashcard Decks")
    }

    private func addCardSet() {
        withAnimation {
            let newCardSet = CardSet(context: viewContext)
            newCardSet.name = "New Deck"
            newCardSet.createdDate = Date()

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteCardSets(offsets: IndexSet) {
        withAnimation {
            offsets.map { cardSets[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter
}()

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
