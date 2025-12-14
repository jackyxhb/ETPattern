//
//  DesignSystem.swift
//  ETPattern
//
//  Created by admin on 28/11/2025.
//

import Foundation
import SwiftUI

struct DesignSystem {
    struct Colors {
        static let backgroundStart = Color(red: 18/255, green: 22/255, blue: 41/255)
        static let backgroundEnd = Color(red: 42/255, green: 49/255, blue: 89/255)
        static let cardTop = Color(red: 44/255, green: 50/255, blue: 92/255)
        static let cardBottom = Color(red: 25/255, green: 27/255, blue: 54/255)
        static let highlight = Color(red: 74/255, green: 217/255, blue: 182/255)
        static let accentPurple = Color(red: 124/255, green: 97/255, blue: 255/255)
        static let accentBlue = Color(red: 95/255, green: 176/255, blue: 255/255)
        static let accentPink = Color(red: 255/255, green: 90/255, blue: 167/255)
        static let surface = Color.white.opacity(0.08)
        static let stroke = Color.white.opacity(0.2)
    }

    struct Gradients {
        static var background: LinearGradient {
            LinearGradient(colors: [Colors.backgroundStart, Colors.backgroundEnd], startPoint: .topLeading, endPoint: .bottomTrailing)
        }

        static var card: LinearGradient {
            LinearGradient(colors: [Colors.cardTop, Colors.cardBottom], startPoint: .topLeading, endPoint: .bottomTrailing)
        }

        static var accent: LinearGradient {
            LinearGradient(colors: [Colors.accentPurple, Colors.accentBlue], startPoint: .leading, endPoint: .trailing)
        }

        static var danger: LinearGradient {
            LinearGradient(colors: [Color(red: 255/255, green: 98/255, blue: 98/255), Colors.accentPink], startPoint: .leading, endPoint: .trailing)
        }

        static var success: LinearGradient {
            LinearGradient(colors: [Colors.highlight, Colors.accentBlue], startPoint: .leading, endPoint: .trailing)
        }
    }

    struct Metrics {
        static let cornerRadius: CGFloat = 24
        static let smallCornerRadius: CGFloat = 16
        static let shadow = Color.black.opacity(0.35)
    }
}