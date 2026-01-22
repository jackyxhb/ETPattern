import SwiftUI
import ETPatternModels
import ETPatternCore
import ETPatternServices

public struct EditCardView: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    
    @State public var viewModel: EditCardViewModel
    
    public init(viewModel: EditCardViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }
    
    public var body: some View {
        ZStack {
            LiquidBackground()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Card Content Group
                        VStack(spacing: 20) {
                            inputSection(title: "Front Content", text: $viewModel.frontText, placeholder: "Enter phrase or pattern...")
                            
                            Divider()
                                .background(theme.colors.textSecondary.opacity(0.2))
                            
                            inputSection(title: "Back Content", text: $viewModel.backText, placeholder: "Enter translation or examples...")
                        }
                        .bentoTileStyle()
                        .padding(.horizontal)
                        
                        if let error = viewModel.errorMessage {
                            errorMessageView(error)
                        }
                    }
                    .padding(.vertical, 24)
                }
                
                // FAB Save Button
                saveButton
            }
        }
        .themedPresentation()
    }
    
    // MARK: - Components
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.title)
                    .font(.title3.bold())
                    .foregroundColor(theme.colors.textPrimary)
                Text(viewModel.isNewCard ? "Create a new flashcard" : "Modify existing card")
                    .font(.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }
            Spacer()
            Button(action: { viewModel.cancel() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(theme.colors.textSecondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }
    
    private func inputSection(title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(theme.colors.highlight)
                .textCase(.uppercase)
            
            TextField(placeholder, text: text, axis: .vertical)
                .font(.body)
                .padding(12)
                .background(theme.colors.surfaceLight.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(theme.colors.textSecondary.opacity(0.1), lineWidth: 1)
                )
        }
    }
    
    private var saveButton: some View {
        Button(action: {
            Task {
                await viewModel.save()
            }
        }) {
            HStack(spacing: 12) {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                }
                Text("Save Card")
                    .fontWeight(.bold)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 32)
            .background(theme.gradients.accent)
            .foregroundColor(.white)
            .clipShape(Capsule())
            .shadow(color: theme.colors.highlight.opacity(0.3), radius: 10, y: 5)
        }
        .padding(.bottom, 24)
        .disabled(viewModel.isLoading)
    }
    
    private func errorMessageView(_ error: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(error)
        }
        .font(.caption)
        .foregroundColor(theme.colors.danger)
        .padding(.horizontal)
    }
}
