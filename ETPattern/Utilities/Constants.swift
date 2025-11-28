//
//  Constants.swift
//  ETPattern
//
//  Created by admin on 28/11/2025.
//

import Foundation

struct Constants {
    struct TTS {
        static let defaultVoice = "en-US"
        static let britishVoice = "en-GB"
        static let naturalRate: Float = 0.5
        static let minRate: Float = 0.48
        static let maxRate: Float = 0.52
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
}