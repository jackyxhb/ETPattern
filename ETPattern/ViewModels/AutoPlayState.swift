//
//  AutoPlayState.swift
//  ETPattern
//
//  FSM State and Action definitions for AutoPlay
//

import Foundation

/// States for the AutoPlay finite state machine
public enum AutoPlayState: Equatable, CustomStringConvertible {
    case idle               // Paused, waiting for user
    case speakingFront      // TTS reading front of card
    case waitingFlip        // Pause before flip animation
    case flipping           // Flip animation in progress
    case speakingBack       // TTS reading back of card
    case waitingNext        // Pause before advancing to next card
    case advancingCard      // Loading next card
    
    public var description: String {
        switch self {
        case .idle: return "Idle"
        case .speakingFront: return "Speaking Front"
        case .waitingFlip: return "Waiting to Flip"
        case .flipping: return "Flipping"
        case .speakingBack: return "Speaking Back"
        case .waitingNext: return "Waiting for Next"
        case .advancingCard: return "Advancing Card"
        }
    }
    
    /// Whether TTS should be active in this state
    public var isSpeaking: Bool {
        self == .speakingFront || self == .speakingBack
    }
    
    /// Whether a timer should be active in this state
    public var isWaiting: Bool {
        self == .waitingFlip || self == .waitingNext
    }
    
    /// Whether the FSM is in an "active" (non-idle) state
    public var isActive: Bool {
        self != .idle
    }
}

/// Actions that can be sent to the AutoPlay FSM
public enum AutoPlayAction: Equatable {
    // User actions
    case start              // Initial start
    case pause              // User pauses playback
    case resume             // User resumes from idle
    case next               // User skips to next card
    case prev               // User goes to previous card
    case flip               // User manually flips card
    case dismiss            // User closes AutoPlay
    
    // Internal events
    case ttsDone            // TTS finished speaking
    case timerDone          // Timer elapsed
    case flipDone           // Flip animation completed
    case cardLoaded         // New card loaded
}
