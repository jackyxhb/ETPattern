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
                .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    progressColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)

            Text("\(Int(progress * 100))%")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
        }
        .frame(width: size, height: size)
    }

    private var progressColor: Color {
        switch progress {
        case 0..<0.5:
            return .red
        case 0.5..<0.8:
            return .orange
        default:
            return .green
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