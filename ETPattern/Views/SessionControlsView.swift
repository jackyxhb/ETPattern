//
//  SessionControlsView.swift
//  ETPattern
//
//  Created by admin on 15/12/2025.
//

import SwiftUI

struct SessionControlsView: View {
    @ObservedObject var sessionManager: SessionManager
    let closeAction: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar at the top of the control bar
            HStack(spacing: 12) {
                let currentPosition = sessionManager.sessionCardList.count > 0 ?
                    ((sessionManager.cardsStudiedInSession % sessionManager.sessionCardList.count) + 1) : 0
                Text("\(currentPosition)/\(sessionManager.sessionCardList.count)")
                    .font(.caption.bold())
                    .foregroundColor(.white.opacity(0.8))

                ProgressView(value: sessionManager.progress)
                    .tint(DesignSystem.Colors.highlight)
                    .frame(height: 4)

                if let accuracy = sessionManager.currentAccuracy, accuracy > 0 {
                    Text("\(Int(accuracy * 100))%")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)

            // Main control buttons - Order, Again, Flip, Easy, Close
            HStack(spacing: 12) {
                // Order toggle button
                Button(action: {
                    UIImpactFeedbackGenerator.lightImpact()
                    sessionManager.toggleOrderMode()
                }) {
                    Image(systemName: sessionManager.isRandomOrder ? "shuffle" : "arrow.up.arrow.down")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                }
                .accessibilityLabel(sessionManager.isRandomOrder ? "Random Order" : "Sequential Order")

                // Again button - put current card into "again" queue
                Button(action: {
                    UIImpactFeedbackGenerator.mediumImpact()
                    sessionManager.markAsAgain()
                }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 44, height: 44)
                        .background(DesignSystem.Gradients.danger)
                        .clipShape(Circle())
                }
                .accessibilityLabel("Again")

                // Flip button - just flip current card
                Button(action: {
                    UIImpactFeedbackGenerator.lightImpact()
                    sessionManager.flipCard()
                }) {
                    Image(systemName: sessionManager.isFlipped ? "arrow.uturn.backward" : "arrow.right")
                        .font(.title)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                        .shadow(color: DesignSystem.Colors.highlight.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .accessibilityLabel("Flip Card")

                // Easy button - current card could be passed due to that it's too easy
                Button(action: {
                    UIImpactFeedbackGenerator.mediumImpact()
                    sessionManager.markAsEasy()
                }) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(DesignSystem.Gradients.success)
                        .clipShape(Circle())
                }
                .accessibilityLabel("Easy")

                // Close button - close the view
                Button(action: {
                    UIImpactFeedbackGenerator.lightImpact()
                    sessionManager.closeSession()
                    closeAction()
                }) {
                    Image(systemName: "xmark")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Close Session")
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            .padding(.top, 8)

            // Swipe instructions at the bottom
            Text("Swipe left for Again · Swipe right for Easy")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
        }
        .background(.ultraThinMaterial)
    }
}