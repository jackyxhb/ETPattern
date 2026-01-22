//
//  ProgressCircle.swift
//  ETPattern
//
//  Created by admin on 29/11/2025.
//

import SwiftUI
import ETPatternCore

struct ProgressCircle: View {
    @Environment(\.theme) var theme
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(theme.colors.surfaceLight, lineWidth: theme.metrics.progressCircleLineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    progressGradient,
                    style: StrokeStyle(lineWidth: theme.metrics.progressCircleLineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.bouncy, value: progress)

            Text(String(format: NSLocalizedString("progress_percentage", comment: "Progress percentage display"), Int(progress * 100)))
                .font(.system(size: theme.metrics.progressCircleFontSize, weight: .semibold, design: .rounded))
                .foregroundColor(theme.colors.textPrimary)
        }
        .frame(width: theme.metrics.progressCircleSize, height: theme.metrics.progressCircleSize)
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
    VStack(spacing: Theme.dark.metrics.previewSpacing) {
        ProgressCircle(progress: 0.0)
        ProgressCircle(progress: 0.5)
        ProgressCircle(progress: 0.8)
        ProgressCircle(progress: 1.0)
    }
}