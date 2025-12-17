//
//  StudySessionTests.swift
//  ETPatternUITests
//
//  Created by GitHub Copilot on 02/12/2025.
//

import XCTest

final class StudySessionTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func startStudySession(app: XCUIApplication) {
        let firstDeck = app.buttons.matching(identifier: "deckCard").element(boundBy: 0)
        XCTAssertTrue(firstDeck.waitForExistence(timeout: 8), "Deck list is empty")
        firstDeck.tap()

        let studyButton = app.buttons["Study"]
        XCTAssertTrue(studyButton.waitForExistence(timeout: 5))
        studyButton.tap()
    }

    @MainActor
    func testAgainAndEasyButtonsExist() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
        startStudySession(app: app)

        let againButton = app.buttons["Again"]
        let easyButton = app.buttons["Easy"]
        XCTAssertTrue(againButton.waitForExistence(timeout: 5))
        XCTAssertTrue(easyButton.waitForExistence(timeout: 5))

        againButton.forceTap()
        easyButton.forceTap()

        XCTAssertTrue(app.navigationBars["Study Session"].exists || app.staticTexts["Session Complete!"].exists)
    }

    @MainActor
    func testNavigationShortcuts() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()

        let statsButton = app.buttons["chart.bar"]
        XCTAssertTrue(statsButton.exists)
        statsButton.tap()
        XCTAssertTrue(app.navigationBars["Study Sessions"].waitForExistence(timeout: 3))
        app.navigationBars["Study Sessions"].buttons["Done"].forceTap()

        let importButton = app.buttons["square.and.arrow.down"]
        XCTAssertTrue(importButton.exists)
        importButton.tap()
        XCTAssertTrue(app.staticTexts["Import CSV File"].waitForExistence(timeout: 3))
        if app.navigationBars.buttons.count > 0 {
            app.navigationBars.buttons.element(boundBy: 0).forceTap()
        }

        let settingsButton = app.buttons["gear"]
        XCTAssertTrue(settingsButton.exists)
        settingsButton.tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))
        if app.navigationBars.buttons.count > 0 {
            app.navigationBars.buttons.element(boundBy: 0).forceTap()
        }
    }
}
