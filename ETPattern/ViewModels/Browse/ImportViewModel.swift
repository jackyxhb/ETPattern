import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import ETPatternModels
import ETPatternServices
import ETPatternCore

@Observable @MainActor
public class ImportViewModel {
    public var isShowingFilePicker = false
    public var isImporting = false
    public var importError: String?
    public var showErrorAlert = false
    
    public let csvFormatHeader = "Front;;Back;;Tags"
    public let csvFormatSubsequent = "Pattern;;Examples<br>More examples;;tag1,tag2"
    public let csvFormatSeparator = ";; (double semicolon)"
    public let csvFormatLineBreak = "<br>"
    
    private let modelContext: ModelContext
    private let csvImporter: CSVImporter
    private weak var coordinator: BrowseCoordinator?
    
    public init(modelContext: ModelContext, coordinator: BrowseCoordinator?) {
        self.modelContext = modelContext
        self.csvImporter = CSVImporter(modelContext: modelContext)
        self.coordinator = coordinator
    }
    
    public func handleFileSelection(_ result: Result<[URL], Error>) {
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
        importError = nil
        
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
            let cardSet = CardSet(name: cardSetName)
            modelContext.insert(cardSet)
            
            // Sort cards by ID to ensure proper order and add to cardSet
            let sortedCards = cards.sorted { $0.id < $1.id }
            for card in sortedCards {
                card.cardSet = cardSet
                cardSet.cards.append(card)
                modelContext.insert(card)
            }
            
            try modelContext.save()
            
            // Success - dismiss the view
            isImporting = false
            coordinator?.dismissImport()
            
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
