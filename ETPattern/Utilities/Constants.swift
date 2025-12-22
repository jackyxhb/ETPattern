//
//  Constants.swift
//  ETPattern
//
//  Created by admin on 28/11/2025.
//

import Foundation
import SwiftUI

@MainActor
struct Constants {
    struct TTS {
        static let defaultVoice = "en-US"
        static let britishVoice = "en-GB"
        static let naturalRate: Float = 0.5
        static let minPercentage: Float = 50.0  // 50%
        static let maxPercentage: Float = 120.0 // 120%
        static let defaultPercentage: Float = 100.0 // 100%
        static let defaultPitch: Float = 1.0 // 100%
        static let minPitch: Float = 0.5 // 50%
        static let maxPitch: Float = 2.0 // 200%
        static let defaultVolume: Float = 1.0 // 100%
        static let minVolume: Float = 0.0 // 0%
        static let maxVolume: Float = 1.0 // 100%
        static let defaultPause: TimeInterval = 0.0 // 0 seconds
        static let minPause: TimeInterval = 0.0 // 0 seconds
        static let maxPause: TimeInterval = 2.0 // 2 seconds

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
        // Bundled master deck name (represents all 300 patterns)
        static let bundledMasterName = "ETPattern 300"
        static let legacyBundledMasterName = "ETPatterns 300"
    }
}