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
            VStack(spacing: 24) {
                // Session Info
                VStack(alignment: .leading, spacing: 16) {
                    Text("Session Management")
                        .font(.title2.bold())
                        .foregroundColor(theme.colors.textPrimary)

                    VStack(alignment: .leading, spacing: 12) {
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
                                    .foregroundColor(.white.opacity(0.7))
                                Text(String(format: "%.1f%%", accuracy))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)

                // Management Actions
                VStack(spacing: 16) {
                    Button(action: {
                        // Reset current session
                        onResetSession()
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset Session")
                        }
                        .font(.headline)
                        .foregroundColor(theme.colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(theme.colors.danger.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button(action: {
                        // Could add more session management options here
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "checkmark")
                            Text("Continue Studying")
                        }
                        .font(.headline)
                        .foregroundColor(theme.colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(theme.gradients.success)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 40)
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