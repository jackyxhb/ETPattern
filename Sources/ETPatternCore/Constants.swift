//
//  Constants.swift
//  ETPattern
//
//  Created by admin on 28/11/2025.
//

import Foundation
import CoreGraphics

public struct Constants {
    public struct TTS {
        public static let defaultVoice = "en-US"
        public static let britishVoice = "en-GB"
        public static let naturalRate: Float = 0.5
        public static let minPercentage: Float = 50.0  // 50%
        public static let maxPercentage: Float = 120.0 // 120%
        public static let defaultPercentage: Float = 100.0 // 100%
        public static let defaultPitch: Float = 1.0 // 100%
        public static let minPitch: Float = 0.5 // 50%
        public static let maxPitch: Float = 2.0 // 200%
        public static let defaultVolume: Float = 1.0 // 100%
        public static let minVolume: Float = 0.0 // 0%
        public static let maxVolume: Float = 1.0 // 100%
        public static let defaultPause: TimeInterval = 0.0 // 0 seconds
        public static let minPause: TimeInterval = 0.0 // 0 seconds
        public static let maxPause: TimeInterval = 2.0 // 2 seconds

        // Convert percentage to AVSpeechSynthesizer rate
        public static func percentageToRate(_ percentage: Float) -> Float {
            return percentage / 200.0  // 50% = 0.25, 100% = 0.5, 120% = 0.6
        }

        // Convert AVSpeechSynthesizer rate to percentage
        public static func rateToPercentage(_ rate: Float) -> Float {
            return rate * 200.0  // 0.25 = 50%, 0.5 = 100%, 0.6 = 120%
        }
    }

    public struct SpacedRepetition {
        public static let defaultEaseFactor: Double = 2.5
        public static let minEaseFactor: Double = 1.3
        public static let maxEaseFactor: Double = 2.5
        public static let againInterval: Int32 = 1
        public static let easyMultiplier: Double = 1.5
        public static let easeIncrement: Double = 0.1
        public static let easeDecrement: Double = 0.2
    }

    public struct UI {
        public static let cardCornerRadius: CGFloat = 12
        public static let cardPadding: CGFloat = 20
        public static let animationDuration: Double = 0.6
    }

    public struct Decks {
        // Bundled master deck name (represents all 300 patterns)
        public static let bundledMasterName = "ETPattern 300"
        public static let legacyBundledMasterName = "ETPatterns 300"
    }
}
