//
//  SessionManagementView.swift
//  ETPattern
//
//  Created by admin on 6/12/2025.
//

import SwiftUI
import CoreData

struct SessionManagementView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) var theme

    let cardSetName: String
    let cardsReviewed: Int
    let correctCount: Int
    let onResetSession: () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: theme.metrics.largeSpacing) {
                // Session Info
                VStack(alignment: .leading, spacing: theme.metrics.mediumSpacing) {
                    Text("Session Management")
                        .font(theme.typography.title2.bold())
                        .foregroundColor(theme.colors.textPrimary)

                    VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                        HStack {
                            Text("Deck:")
                                .foregroundColor(theme.colors.textSecondary)
                            Text(cardSetName)
                                .foregroundColor(theme.colors.textPrimary)
                        }

                        HStack {
                            Text("Cards Reviewed:")
                                .foregroundColor(theme.colors.textSecondary)
                            Text("\(cardsReviewed)")
                                .foregroundColor(theme.colors.textPrimary)
                        }

                        HStack {
                            Text("Correct Answers:")
                                .foregroundColor(theme.colors.textSecondary)
                            Text("\(correctCount)")
                                .foregroundColor(theme.colors.textPrimary)
                        }

                        if cardsReviewed > 0 {
                            let accuracy = Double(correctCount) / Double(cardsReviewed) * 100
                            HStack {
                                Text("Accuracy:")
                                    .foregroundColor(theme.colors.textSecondary)
                                Text(String(format: "%.1f%%", accuracy))
                                    .foregroundColor(theme.colors.textPrimary)
                            }
                        }
                    }
                    .padding(theme.metrics.buttonPadding)
                    .background(theme.colors.surfaceMedium)
                    .clipShape(RoundedRectangle(cornerRadius: theme.metrics.cornerRadius))
                }
                .padding(.horizontal, theme.metrics.mediumSpacing)

                // Management Actions
                VStack(spacing: theme.metrics.mediumSpacing) {
                    Button(action: {
                        // Reset current session
                        onResetSession()
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset Session")
                        }
                        .font(theme.typography.headline)
                        .foregroundColor(theme.colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(theme.metrics.buttonPadding)
                        .background(theme.colors.danger.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: theme.metrics.cornerRadius))
                    }

                    Button(action: {
                        // Could add more session management options here
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "checkmark")
                            Text("Continue Studying")
                        }
                        .font(theme.typography.headline)
                        .foregroundColor(theme.colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(theme.metrics.buttonPadding)
                        .background(theme.gradients.success)
                        .clipShape(RoundedRectangle(cornerRadius: theme.metrics.cornerRadius))
                    }
                }
                .padding(.horizontal, theme.metrics.mediumSpacing)

                Spacer()
            }
            .padding(.top, theme.metrics.largeSpacing * 1.67)
            .background(theme.gradients.background.ignoresSafeArea())
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }

    private func resetSession() {
        onResetSession()
    }
}