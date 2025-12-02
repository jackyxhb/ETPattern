//
//  CardFlipTests.swift
//  ETPatternUITests
//
//  Created by GitHub Copilot on 02/12/2025.
//

import XCTest

final class CardFlipTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testCardFlipFromDeckList() throws {
        let app = XCUIApplication()
        app.launch()

        let firstDeckCell = app.tables.cells.element(boundBy: 0)
        XCTAssertTrue(firstDeckCell.waitForExistence(timeout: 5), "Deck list did not load")
        firstDeckCell.tap()

        let studyButton = app.buttons["Study"]
        XCTAssertTrue(studyButton.waitForExistence(timeout: 5), "Study button missing on deck detail")
        studyButton.tap()

        let card = app.otherElements.element(boundBy: 0)
        XCTAssertTrue(card.waitForExistence(timeout: 5), "Card view did not appear")

        card.tap() // Flip to back
        card.tap() // Flip to front

        XCTAssertTrue(app.navigationBars["Study Session"].exists, "Study session should remain active after flips")
    }

    @MainActor
    func testCardSwipeGestures() throws {
        let app = XCUIApplication()
        app.launch()

        let firstDeckCell = app.tables.cells.element(boundBy: 0)
        XCTAssertTrue(firstDeckCell.waitForExistence(timeout: 5))
        firstDeckCell.tap()

        let studyButton = app.buttons["Study"]
        XCTAssertTrue(studyButton.waitForExistence(timeout: 5))
        studyButton.tap()

        let card = app.otherElements.element(boundBy: 0)
        XCTAssertTrue(card.waitForExistence(timeout: 5))

        card.swipeRight() // Easy
        card.swipeLeft()  // Again

        XCTAssertTrue(app.navigationBars["Study Session"].exists || app.staticTexts["Session Complete!"].exists)
    }
}
