//
//  Constants.swift
//  ETPattern
//
//  Created by admin on 28/11/2025.
//

import Foundation
import SwiftUI

struct Constants {
    struct TTS {
        static let defaultVoice = "en-US"
        static let britishVoice = "en-GB"
        static let naturalRate: Float = 0.5
        static let minPercentage: Float = 50.0  // 50%
        static let maxPercentage: Float = 120.0 // 120%
        static let defaultPercentage: Float = 100.0 // 100%
        
        // Convert percentage to AVSpeechSynthesizer rate
        static func percentageToRate(_ percentage: Float) -> Float {
            return percentage / 200.0  // 50% = 0.25, 100% = 0.5, 120% = 0.6
        }
        
        // Convert AVSpeechSynthesizer rate to percentage
        static func rateToPercentage(_ rate: Float) -> Float {
            return rate * 200.0  // 0.25 = 50%, 0.5 = 100%, 0.6 = 120%
        }
    }

    struct SpacedRepetition {
        static let defaultEaseFactor: Double = 2.5
        static let minEaseFactor: Double = 1.3
        static let maxEaseFactor: Double = 2.5
        static let againInterval: Int32 = 1
        static let easyMultiplier: Double = 1.5
        static let easeIncrement: Double = 0.1
        static let easeDecrement: Double = 0.2
    }

    struct UI {
        static let cardCornerRadius: CGFloat = 12
        static let cardPadding: CGFloat = 20
        static let animationDuration: Double = 0.6
    }

    struct Decks {
        static let bundledMasterName = "ETPatterns 300"
    }
}

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