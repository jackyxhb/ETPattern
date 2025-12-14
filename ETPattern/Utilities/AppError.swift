//
//  AppError.swift
//  ETPattern
//
//  Created by admin on 14/12/2025.
//

import Foundation

enum AppError: LocalizedError {
    case csvImportFailed(reason: String)
    case csvFileNotFound(fileName: String)
    case csvParsingFailed(reason: String)
    case coreDataSaveFailed(reason: String)
    case ttsFailed(reason: String)
    case ttsVoiceNotAvailable(voice: String)
    case fileAccessFailed(reason: String)

    var errorDescription: String? {
        switch self {
        case .csvImportFailed(let reason):
            return "CSV Import Failed: \(reason)"
        case .csvFileNotFound(let fileName):
            return "CSV file not found: \(fileName)"
        case .csvParsingFailed(let reason):
            return "CSV parsing failed: \(reason)"
        case .coreDataSaveFailed(let reason):
            return "Failed to save data: \(reason)"
        case .ttsFailed(let reason):
            return "Text-to-speech failed: \(reason)"
        case .ttsVoiceNotAvailable(let voice):
            return "Voice not available: \(voice)"
        case .fileAccessFailed(let reason):
            return "File access failed: \(reason)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .csvImportFailed:
            return "Please check the CSV file format and try again."
        case .csvFileNotFound:
            return "Please ensure the CSV file exists and try again."
        case .csvParsingFailed:
            return "Please check that the CSV follows the required format: Front;;Back;;Tags"
        case .coreDataSaveFailed:
            return "Please try again. If the problem persists, restart the app."
        case .ttsFailed:
            return "Please check your device settings and try again."
        case .ttsVoiceNotAvailable:
            return "Please select a different voice in Settings."
        case .fileAccessFailed:
            return "Please check file permissions and try again."
        }
    }
}