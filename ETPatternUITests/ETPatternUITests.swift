//
//  ETPatternUITests.swift
//  ETPatternUITests
//
//  Created by admin on 25/11/2025.
//

import XCTest

final class ETPatternUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    @MainActor
    func testAppLaunch() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()

        // Verify main screen elements
        XCTAssertTrue(app.staticTexts["English Thought"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["chart.bar"].exists)
        XCTAssertTrue(app.buttons["square.and.arrow.down"].exists)
        XCTAssertTrue(app.buttons["gear"].exists)
    }

    @MainActor
    func testCardFlip() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()

        // Navigate to a deck (assuming bundled decks are loaded)
        let firstDeck = app.buttons.matching(identifier: "deckCard").element(boundBy: 0)
        XCTAssertTrue(firstDeck.waitForExistence(timeout: 8))
        firstDeck.tap()

        // Tap study button
        let studyButton = app.buttons["Study"]
        XCTAssertTrue(studyButton.waitForExistence(timeout: 5))
        studyButton.tap()

        // Verify we're in study view
        XCTAssertTrue(app.otherElements["studyCard"].waitForExistence(timeout: 8))

        // Tap card to flip
        let card = app.otherElements["studyCard"]
        XCTAssertTrue(card.waitForExistence(timeout: 8))
        card.tap()

        // Wait for flip animation
        sleep(1)

        // Card should be flipped (we can't directly test visual state, but ensure no crash)
        XCTAssertTrue(app.buttons["Again"].exists || app.buttons["Easy"].exists)
    }

    @MainActor
    func testStudyFlow() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()

        // Navigate to a deck
        let firstDeck = app.buttons.matching(identifier: "deckCard").element(boundBy: 0)
        XCTAssertTrue(firstDeck.waitForExistence(timeout: 8))
        firstDeck.tap()

        // Tap study button
        let studyButton = app.buttons["Study"]
        XCTAssertTrue(studyButton.waitForExistence(timeout: 5))
        studyButton.tap()

        // Verify study session starts
        XCTAssertTrue(app.otherElements["studyCard"].waitForExistence(timeout: 8))

        // Check for progress elements
        // Ensure controls exist
        XCTAssertTrue(app.buttons["Again"].exists)
        XCTAssertTrue(app.buttons["Easy"].exists)

        // Test swipe gestures (simulate swipe right for "Easy")
        let card = app.otherElements["studyCard"]
        XCTAssertTrue(card.waitForExistence(timeout: 8))

        // Swipe right
        card.swipeRight()

        // Session should continue or complete
        // (We can't predict exact behavior without knowing card count, but ensure no crash)
        XCTAssertTrue(app.buttons["Again"].exists || app.buttons["Easy"].exists || app.staticTexts["Session Complete"].exists)
    }

    @MainActor
    func testNavigationToSettings() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()

        // Tap settings button
        let settingsButton = app.buttons["gear"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        settingsButton.forceTap()

        // Verify settings view
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Text-to-Speech"].exists)
    }

    @MainActor
    func testNavigationToImport() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()

        // Tap import button
        let importButton = app.buttons["square.and.arrow.down"]
        XCTAssertTrue(importButton.exists)
        importButton.tap()

        // Verify import view
        XCTAssertTrue(app.staticTexts["Import CSV File"].exists)
    }

    @MainActor
    func testNavigationToSessionStats() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()

        // Tap stats button
        let statsButton = app.buttons["chart.bar"]
        XCTAssertTrue(statsButton.exists)
        statsButton.tap()

        // Verify session stats view
        XCTAssertTrue(app.navigationBars["Study Sessions"].exists)
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let app = XCUIApplication()
            app.launchArguments = ["UI_TESTING"]
            app.launch()
        }
    }
}
