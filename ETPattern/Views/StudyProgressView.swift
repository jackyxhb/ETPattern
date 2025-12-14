//
//  ProgressView.swift
//  ETPattern
//
//  Created by admin on 15/12/2025.
//

import SwiftUI

struct StudyProgressView: View {
    @ObservedObject var sessionManager: SessionManager

    var body: some View {
        HStack(spacing: 16) {
            ProgressCircle(progress: sessionManager.progress)
                .frame(width: 70, height: 70)

            VStack(alignment: .leading, spacing: 6) {
                Text("Card \(sessionManager.currentCardNumber) of \(max(sessionManager.totalCardsInSession, 1))")
                    .font(.headline)
                    .foregroundColor(.white)
                if let accuracy = sessionManager.currentAccuracy, accuracy > 0 {
                    Text("Accuracy \(Int(accuracy * 100))%")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text("Today")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                Text("Total: \(sessionManager.totalCardsInSession)")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("Remaining: \(sessionManager.cardsRemaining)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

// Assuming ProgressCircle is defined elsewhere, if not, we can add it here