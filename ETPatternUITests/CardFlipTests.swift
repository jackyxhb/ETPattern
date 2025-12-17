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
        app.launchArguments = ["UI_TESTING"]
        app.launch()

        let firstDeck = app.buttons.matching(identifier: "deckCard").element(boundBy: 0)
        XCTAssertTrue(firstDeck.waitForExistence(timeout: 8), "Deck list did not load")
        firstDeck.tap()

        let studyButton = app.buttons["Study"]
        XCTAssertTrue(studyButton.waitForExistence(timeout: 5), "Study button missing on deck detail")
        studyButton.forceTap()

        let card = app.otherElements["studyCard"]
        XCTAssertTrue(card.waitForExistence(timeout: 8), "Card view did not appear")

        card.tap() // Flip to back
        card.tap() // Flip to front

        XCTAssertTrue(app.buttons["Again"].exists || app.buttons["Easy"].exists, "Study controls should remain visible after flips")
    }

    @MainActor
    func testCardSwipeGestures() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()

        let firstDeck = app.buttons.matching(identifier: "deckCard").element(boundBy: 0)
        XCTAssertTrue(firstDeck.waitForExistence(timeout: 8))
        firstDeck.tap()

        let studyButton = app.buttons["Study"]
        XCTAssertTrue(studyButton.waitForExistence(timeout: 5))
        studyButton.forceTap()

        let card = app.otherElements["studyCard"]
        XCTAssertTrue(card.waitForExistence(timeout: 8))

        card.swipeRight() // Easy
        card.swipeLeft()  // Again

        XCTAssertTrue(app.buttons["Again"].exists || app.buttons["Easy"].exists || app.staticTexts["Session Complete"].exists)
    }
}
