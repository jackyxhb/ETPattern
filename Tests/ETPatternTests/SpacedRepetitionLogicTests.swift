//
//  SpacedRepetitionLogicTests.swift
//  ETPatternTests
//
//  Created by admin on 25/12/2025.
//

import XCTest
@testable import ETPatternCore

final class SpacedRepetitionLogicTests: XCTestCase {

    func testAgianRatingResetsInterval() {
        let result = SpacedRepetitionLogic.calculateNextReview(currentInterval: 10, currentEaseFactor: 2.5, rating: .again)
        
        XCTAssertEqual(result.interval, 1)
        XCTAssertEqual(result.easeFactor, 2.3) // 2.5 - 0.2
    }
    
    func testAgainRatingEaseFactorMin() {
        let result = SpacedRepetitionLogic.calculateNextReview(currentInterval: 10, currentEaseFactor: 1.3, rating: .again)
        
        XCTAssertEqual(result.interval, 1)
        XCTAssertEqual(result.easeFactor, 1.3) // Max(1.3, 1.3 - 0.2)
    }

    func testEasyRatingIncreases() {
        // interval = 4 * 2.5 * 1.5 = 15
        let result = SpacedRepetitionLogic.calculateNextReview(currentInterval: 4, currentEaseFactor: 2.5, rating: .easy)
        
        XCTAssertEqual(result.interval, 13)
        XCTAssertEqual(result.easeFactor, 2.5) // Clamped to 2.5
    }
    
    func testEasyRatingEaseFactorMax() {
        let result = SpacedRepetitionLogic.calculateNextReview(currentInterval: 4, currentEaseFactor: 2.5, rating: .easy)
        XCTAssertEqual(result.easeFactor, 2.5)
    }
    
    func testEasyRatingEaseFactorIncreaseBelowMax() {
        let result = SpacedRepetitionLogic.calculateNextReview(currentInterval: 4, currentEaseFactor: 2.0, rating: .easy)
        XCTAssertEqual(result.easeFactor, 2.15)
    }
}
