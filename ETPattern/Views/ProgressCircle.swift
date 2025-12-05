//
//  ProgressCircle.swift
//  ETPattern
//
//  Created by admin on 29/11/2025.
//

import SwiftUI

struct ProgressCircle: View {
    let progress: Double
    let lineWidth: CGFloat = 8
    let size: CGFloat = 60

    var body: some View {
        ZStack {
            Circle()
                .stroke(DesignSystem.Colors.stroke, lineWidth: lineWidth)

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
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
    }

    private var progressGradient: LinearGradient {
        switch progress {
        case 0..<0.3:
            return DesignSystem.Gradients.danger
        case 0.3..<0.7:
            return LinearGradient(colors: [Color.orange, Color.yellow], startPoint: .leading, endPoint: .trailing)
        default:
            return DesignSystem.Gradients.success
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