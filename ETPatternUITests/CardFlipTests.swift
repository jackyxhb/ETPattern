//
//  CardFlipTests.swift
//  ETPatternUITests
//
//  Created by admin on 28/11/2025.
//

import XCTest

final class CardFlipTests: XCTestCase {

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
    func testCardFlipAnimation() throws {
        // Navigate to study session
        let firstDeck = app.buttons.matching(identifier: "DeckCard").element(boundBy: 0)
        XCTAssertTrue(firstDeck.waitForExistence(timeout: 10))
        firstDeck.tap()

        let studyButton = app.buttons["Study"]
        XCTAssertTrue(studyButton.waitForExistence(timeout: 5))
        studyButton.tap()

        // Verify we're in study view
        XCTAssertTrue(app.navigationBars["Study Session"].exists)

        // Check initial card state (front side)
        let cardView = app.otherElements["StudyCard"]
        XCTAssertTrue(cardView.waitForExistence(timeout: 5))

        // Get initial text
        let initialText = cardView.label

        // Tap to flip
        cardView.tap()

        // Wait for animation
        sleep(1)

        // Verify text changed (back side)
        let flippedText = cardView.label
        XCTAssertNotEqual(initialText, flippedText, "Card should flip and show different text")

        // Tap again to flip back
        cardView.tap()
        sleep(1)

        // Verify back to front
        let finalText = cardView.label
        XCTAssertEqual(initialText, finalText, "Card should flip back to front")
    }

    @MainActor
    func testCardContainsPatternAndExamples() throws {
        // Navigate to study session
        let firstDeck = app.buttons.matching(identifier: "DeckCard").element(boundBy: 0)
        XCTAssertTrue(firstDeck.waitForExistence(timeout: 10))
        firstDeck.tap()

        let studyButton = app.buttons["Study"]
        XCTAssertTrue(studyButton.waitForExistence(timeout: 5))
        studyButton.tap()

        // Check front side has pattern
        let frontText = app.otherElements["StudyCard"].label
        XCTAssertFalse(frontText.isEmpty, "Front should have pattern text")

        // Flip to back
        app.otherElements["StudyCard"].tap()
        sleep(1)

        // Check back side has examples
        let backText = app.otherElements["StudyCard"].label
        XCTAssertFalse(backText.isEmpty, "Back should have examples text")
        XCTAssertTrue(backText.contains("\n"), "Back should contain multiple lines for examples")
    }
}