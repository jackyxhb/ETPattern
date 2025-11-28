//
//  ImportView.swift
//  ETPattern
//
//  Created by admin on 29/11/2025.
//

import SwiftUI
import UniformTypeIdentifiers
import CoreData

struct ImportView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var isShowingFilePicker = false
    @State private var isImporting = false
    @State private var importError: String?
    @State private var showErrorAlert = false

    private let csvImporter: CSVImporter

    init() {
        self.csvImporter = CSVImporter(viewContext: PersistenceController.shared.container.viewContext)
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Import CSV File")
                .font(.title)
                .fontWeight(.bold)

            Text("Select a CSV file to import flashcards. The file should have the format:")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("• First row: Front;;Back;;Tags")
                Text("• Subsequent rows: Pattern;;Examples<br>More examples;;tag1,tag2")
                Text("• Separator: ;; (double semicolon)")
                Text("• Line breaks in examples: <br>")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal)

            Spacer()

            Button(action: {
                isShowingFilePicker = true
            }) {
                HStack {
                    Image(systemName: "doc.badge.plus")
                    Text("Select CSV File")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.horizontal)
            .disabled(isImporting)

            if isImporting {
                ProgressView("Importing...")
                    .padding()
            }

            Spacer()
        }
        .padding()
        .fileImporter(
            isPresented: $isShowingFilePicker,
            allowedContentTypes: [UTType.commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
        .alert("Import Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(importError ?? "Unknown error occurred")
        }
    }

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            importCSV(from: url)
        case .failure(let error):
            showImportError("Failed to select file: \(error.localizedDescription)")
        }
    }

    private func importCSV(from url: URL) {
        isImporting = true

        // Start accessing the security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            showImportError("Cannot access the selected file")
            return
        }

        defer {
            url.stopAccessingSecurityScopedResource()
        }

        do {
            let content = try String(contentsOf: url, encoding: .utf8)

            // Extract filename for card set name
            let fileName = url.deletingPathExtension().lastPathComponent
            let cardSetName = fileName.isEmpty ? "Imported Deck" : fileName

            // Parse CSV and create cards
            let cards = csvImporter.parseCSV(content, cardSetName: cardSetName)

            if cards.isEmpty {
                showImportError("No valid cards found in the CSV file. Please check the format.")
                return
            }

            // Create new CardSet
            let cardSet = CardSet(context: viewContext)
            cardSet.name = cardSetName
            cardSet.createdDate = Date()
            cardSet.addToCards(NSSet(array: cards))

            // Set the cardSet relationship for each card
            for card in cards {
                card.cardSet = cardSet
            }

            try viewContext.save()

            // Success - dismiss the view
            dismiss()

        } catch {
            showImportError("Failed to import CSV: \(error.localizedDescription)")
        }

        isImporting = false
    }

    private func showImportError(_ message: String) {
        importError = message
        showErrorAlert = true
        isImporting = false
    }
}

#Preview {
    ImportView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}