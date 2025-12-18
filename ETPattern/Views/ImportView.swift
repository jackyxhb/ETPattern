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
    @Environment(\.theme) var theme

    @State private var isShowingFilePicker = false
    @State private var isImporting = false
    @State private var importError: String?
    @State private var showErrorAlert = false

    private let csvImporter: CSVImporter

    init() {
        self.csvImporter = CSVImporter(viewContext: PersistenceController.shared.container.viewContext)
    }

    var body: some View {
        ZStack {
            theme.gradients.background
                .ignoresSafeArea()
            VStack(spacing: theme.metrics.largeSpacing) {
                Text("Import CSV File")
                    .font(theme.typography.title)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)

                Text("Select a CSV file to import flashcards. The file should have the format:")
                    .multilineTextAlignment(.center)
                    .foregroundColor(theme.colors.highlight.opacity(0.8))

                VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                    Text("• First row: Front;;Back;;Tags")
                        .foregroundColor(theme.colors.highlight.opacity(0.8))
                    Text("• Subsequent rows: Pattern;;Examples<br>More examples;;tag1,tag2")
                        .foregroundColor(theme.colors.highlight.opacity(0.8))
                    Text("• Separator: ;; (double semicolon)")
                        .foregroundColor(theme.colors.highlight.opacity(0.8))
                    Text("• Line breaks in examples: <br>")
                        .foregroundColor(theme.colors.highlight.opacity(0.8))
                }
                .font(theme.typography.caption)
                .padding(.horizontal, theme.metrics.mediumSpacing)

                Spacer()

                Button(action: {
                    isShowingFilePicker = true
                }) {
                    HStack {
                        Image(systemName: "doc.badge.plus")
                        Text("Select CSV File")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(theme.metrics.buttonPadding)
                    .background(theme.gradients.accent)
                    .foregroundColor(theme.colors.textPrimary)
                    .cornerRadius(theme.metrics.cornerRadius)
                }
                .padding(.horizontal, theme.metrics.mediumSpacing)
                .disabled(isImporting)

                if isImporting {
                    ProgressView("Importing...")
                        .padding(theme.metrics.mediumSpacing)
                        .foregroundColor(theme.colors.textPrimary)
                }

                Spacer()
            }
            .padding(theme.metrics.largeSpacing)
        }
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

            // Sort cards by ID to ensure proper order
            let sortedCards = cards.sorted { $0.id < $1.id }
            cardSet.addToCards(NSSet(array: sortedCards))

            // Set the cardSet relationship for each card
            for card in sortedCards {
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