import SwiftUI
import UniformTypeIdentifiers
import SwiftData
import ETPatternModels
import ETPatternServices
import ETPatternCore
import ETPatternServices

struct ImportView: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) private var dismiss
    
    @State private var viewModel: ImportViewModel
    
    public init(viewModel: ImportViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        ZStack {
            // Background provided by sheet presentation (.ultraThinMaterial)
            
            VStack(spacing: 0) {
                // Custom header for sheet presentation
                HStack {
                    Text(NSLocalizedString("import", comment: "Import screen title"))
                        .font(.headline)
                        .foregroundColor(theme.colors.textPrimary)
                        .dynamicTypeSize(.large ... .accessibility5)
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(theme.colors.textSecondary)
                            .font(.title2)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, theme.metrics.importHeaderVerticalPadding)
                .background(.ultraThinMaterial)
                
                ScrollView {
                    VStack(spacing: theme.metrics.largeSpacing) {
                        Text("Import CSV File")
                            .font(theme.metrics.title)
                            .fontWeight(.bold)
                            .foregroundColor(theme.colors.textPrimary)
                            .dynamicTypeSize(.large ... .accessibility5)
 
                        Text("Select a CSV file to import flashcards. The file should have the format:")
                            .multilineTextAlignment(.center)
                            .foregroundColor(theme.colors.highlight.opacity(0.8))
                            .dynamicTypeSize(.large ... .accessibility5)
 
                VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                    Text("• First row: \(viewModel.csvFormatHeader)")
                        .foregroundColor(theme.colors.highlight.opacity(0.8))
                        .dynamicTypeSize(.large ... .accessibility5)
                    Text("• Subsequent rows: \(viewModel.csvFormatSubsequent)")
                        .foregroundColor(theme.colors.highlight.opacity(0.8))
                        .dynamicTypeSize(.large ... .accessibility5)
                    Text("• Separator: \(viewModel.csvFormatSeparator)")
                        .foregroundColor(theme.colors.highlight.opacity(0.8))
                        .dynamicTypeSize(.large ... .accessibility5)
                    Text("• Line breaks in examples: \(viewModel.csvFormatLineBreak)")
                        .foregroundColor(theme.colors.highlight.opacity(0.8))
                        .dynamicTypeSize(.large ... .accessibility5)
                }
                .font(theme.metrics.caption)
                .padding(.horizontal, theme.metrics.mediumSpacing)
 
                Spacer()
 
                Button(action: {
                    viewModel.isShowingFilePicker = true
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
                    .dynamicTypeSize(.large ... .accessibility5)
                }
                .padding(.horizontal, theme.metrics.mediumSpacing)
                .disabled(viewModel.isImporting)
 
                if viewModel.isImporting {
                    ProgressView("Importing...")
                        .padding(theme.metrics.mediumSpacing)
                        .foregroundColor(theme.colors.textPrimary)
                        .dynamicTypeSize(.large ... .accessibility5)
                }
 
                if let errorMessage = viewModel.importError, !viewModel.isImporting {
                    VStack(spacing: theme.metrics.smallSpacing) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(theme.colors.danger)
                            .font(.title2)
                        
                        Text("Import Failed")
                            .font(.headline)
                            .foregroundColor(theme.colors.danger)
                            .dynamicTypeSize(.large ... .accessibility5)
                        
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(theme.colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .dynamicTypeSize(.large ... .accessibility5)
                            .padding(.horizontal)
                        
                        Button(role: .cancel, action: {
                            viewModel.importError = nil
                            viewModel.showErrorAlert = false
                        }) {
                            Text("Dismiss")
                                .font(.subheadline)
                                .foregroundColor(theme.colors.textPrimary)
                                .padding(.horizontal, theme.metrics.emptyStateButtonHorizontalPadding)
                                .padding(.vertical, theme.metrics.emptyStateButtonVerticalPadding / 2)
                                .background(theme.colors.surfaceLight.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: theme.metrics.cornerRadius / 2))
                                .dynamicTypeSize(.large ... .accessibility5)
                        }
                    }
                    .padding(.vertical, theme.metrics.mediumSpacing)
                    .padding(.horizontal, theme.metrics.mediumSpacing)
                    .background(theme.colors.danger.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: theme.metrics.cornerRadius))
                }
 
                Spacer()
                    }
                    .padding(theme.metrics.largeSpacing)
                }
            }
        }
        .fileImporter(
            isPresented: $viewModel.isShowingFilePicker,
            allowedContentTypes: [UTType.commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            viewModel.handleFileSelection(result)
        }
        .alert("Import Error", isPresented: $viewModel.showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.importError ?? "Unknown error occurred")
                .dynamicTypeSize(.large ... .accessibility5)
        }
    }
}

#Preview {
    let container = PersistenceController.preview.container
    let viewModel = ImportViewModel(modelContext: container.mainContext, coordinator: nil)
    return ImportView(viewModel: viewModel)
        .modelContainer(container)
}