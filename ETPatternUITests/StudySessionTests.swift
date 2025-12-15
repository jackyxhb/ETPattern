//
//  StudySessionTests.swift
//  ETPatternUITests
//
//  Created by admin on 28/11/2025.
//

import XCTest

final class StudySessionTests: XCTestCase {

    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments = ["UITESTING"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
    }

    @MainActor
    func testSwipeEasy() throws {
        // Navigate to study session
        let firstDeck = app.buttons.matching(identifier: "DeckCard").element(boundBy: 0)
        XCTAssertTrue(firstDeck.waitForExistence(timeout: 10))
        firstDeck.tap()

        let studyButton = app.buttons["Study"]
        XCTAssertTrue(studyButton.waitForExistence(timeout: 5))
        studyButton.tap()

        // Verify study session started
        XCTAssertTrue(app.navigationBars["Study Session"].exists)

        // Get initial card text from the card view
        let cardView = app.otherElements["StudyCard"]
        let initialCardText = cardView.label

        // Swipe right for "Easy"
        cardView.swipeRight()

        // Wait for next card or completion
        sleep(2)

        // Verify either next card or session complete
        if app.staticTexts["Session Complete"].exists {
            XCTAssertTrue(app.buttons["Done"].exists)
        } else {
            let newCardText = cardView.label
            XCTAssertNotEqual(initialCardText, newCardText, "Should show next card after easy rating")
        }
    }

    @MainActor
    func testSwipeAgain() throws {
        // Navigate to study session
        let firstDeck = app.buttons.matching(identifier: "DeckCard").element(boundBy: 0)
        XCTAssertTrue(firstDeck.waitForExistence(timeout: 10))
        firstDeck.tap()

        let studyButton = app.buttons["Study"]
        XCTAssertTrue(studyButton.waitForExistence(timeout: 5))
        studyButton.tap()

        // Swipe left for "Again"
        let cardView = app.otherElements["StudyCard"]
        cardView.swipeLeft()

        // Wait for animation
        sleep(2)

        // Card should still be visible (repeating)
        XCTAssertTrue(app.navigationBars["Study Session"].exists)
    }

    @MainActor
    func testProgressTracking() throws {
        // Navigate to study session
        let firstDeck = app.buttons.matching(identifier: "DeckCard").element(boundBy: 0)
        XCTAssertTrue(firstDeck.waitForExistence(timeout: 10))
        firstDeck.tap()

        let studyButton = app.buttons["Study"]
        XCTAssertTrue(studyButton.waitForExistence(timeout: 5))
        studyButton.tap()

        // Check progress elements exist
        XCTAssertTrue(app.progressIndicators.element.exists, "Progress circle should be visible")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'cards'")).element.exists, "Cards counter should be visible")
    }

    @MainActor
    func testSessionCompletion() throws {
        // This test assumes a small deck; in real scenario might need to swipe through all cards
        // Navigate to study session
        let firstDeck = app.buttons.matching(identifier: "DeckCard").element(boundBy: 0)
        XCTAssertTrue(firstDeck.waitForExistence(timeout: 10))
        firstDeck.tap()

        let studyButton = app.buttons["Study"]
        XCTAssertTrue(studyButton.waitForExistence(timeout: 5))
        studyButton.tap()

        // Swipe through cards until completion
        var swipeCount = 0
        while !app.staticTexts["Session Complete"].exists && swipeCount < 10 {
            app.otherElements["StudyCard"].swipeRight()
            sleep(2)
            swipeCount += 1
        }

        if app.staticTexts["Session Complete"].exists {
            XCTAssertTrue(app.buttons["Done"].exists)
            app.buttons["Done"].tap()
            // Should navigate back to deck details
            XCTAssertTrue(app.navigationBars["ETPattern 300"].waitForExistence(timeout: 5))
        }
    }
}