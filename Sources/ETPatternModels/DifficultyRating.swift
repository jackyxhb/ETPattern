//
//  DifficultyRating.swift
//  ETPattern
//
//  Created by admin on 10/01/2026.
//

import Foundation

public enum DifficultyRating: Int, CaseIterable, Codable, Sendable {
    case again = 0
    case hard = 1
    case good = 2
    case easy = 3
}
