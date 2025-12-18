//
//  ProgressCircle.swift
//  ETPattern
//
//  Created by admin on 29/11/2025.
//

import SwiftUI

struct ProgressCircle: View {
    @Environment(\.theme) var theme
    let progress: Double
    let lineWidth: CGFloat = 8
    let size: CGFloat = 60

    var body: some View {
        ZStack {
            Circle()
                .stroke(theme.colors.surfaceLight, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    progressGradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.bouncy, value: progress)

            Text("\(Int(progress * 100))%")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(theme.colors.textPrimary)
        }
        .frame(width: size, height: size)
    }

    private var progressGradient: LinearGradient {
        switch progress {
        case 0..<0.3:
            return theme.gradients.danger
        case 0.3..<0.7:
            return theme.gradients.warning
        default:
            return theme.gradients.success
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ProgressCircle(progress: 0.0)
        ProgressCircle(progress: 0.5)
        ProgressCircle(progress: 0.8)
        ProgressCircle(progress: 1.0)
    }
}