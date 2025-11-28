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
        app.launch()

        // Verify main screen elements
        XCTAssertTrue(app.navigationBars["Flashcard Decks"].exists)
        XCTAssertTrue(app.buttons["chart.bar"].exists)
        XCTAssertTrue(app.buttons["square.and.arrow.down"].exists)
        XCTAssertTrue(app.buttons["gear"].exists)
    }

    @MainActor
    func testCardFlip() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to a deck (assuming bundled decks are loaded)
        let firstDeck = app.staticTexts.element(boundBy: 0)
        XCTAssertTrue(firstDeck.waitForExistence(timeout: 5))
        firstDeck.tap()

        // Tap study button
        let studyButton = app.buttons["Study"]
        XCTAssertTrue(studyButton.waitForExistence(timeout: 5))
        studyButton.tap()

        // Verify we're in study view
        XCTAssertTrue(app.navigationBars["Study Session"].exists)

        // Tap card to flip
        let card = app.otherElements.element(boundBy: 0)
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        card.tap()

        // Wait for flip animation
        sleep(1)

        // Card should be flipped (we can't directly test visual state, but ensure no crash)
        XCTAssertTrue(app.navigationBars["Study Session"].exists)
    }

    @MainActor
    func testStudyFlow() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to a deck
        let firstDeck = app.staticTexts.element(boundBy: 0)
        XCTAssertTrue(firstDeck.waitForExistence(timeout: 5))
        firstDeck.tap()

        // Tap study button
        let studyButton = app.buttons["Study"]
        XCTAssertTrue(studyButton.waitForExistence(timeout: 5))
        studyButton.tap()

        // Verify study session starts
        XCTAssertTrue(app.navigationBars["Study Session"].exists)

        // Check for progress elements
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Cards:'")).element.exists)

        // Test swipe gestures (simulate swipe right for "Easy")
        let card = app.otherElements.element(boundBy: 0)
        XCTAssertTrue(card.waitForExistence(timeout: 5))

        // Swipe right
        card.swipeRight()

        // Session should continue or complete
        // (We can't predict exact behavior without knowing card count, but ensure no crash)
        XCTAssertTrue(app.navigationBars["Study Session"].exists || app.staticTexts["Session Complete!"].exists)
    }

    @MainActor
    func testNavigationToSettings() throws {
        let app = XCUIApplication()
        app.launch()

        // Tap settings button
        let settingsButton = app.buttons["gear"]
        XCTAssertTrue(settingsButton.exists)
        settingsButton.tap()

        // Verify settings view
        XCTAssertTrue(app.navigationBars["Settings"].exists)
        XCTAssertTrue(app.staticTexts["Text-to-Speech"].exists)
    }

    @MainActor
    func testNavigationToImport() throws {
        let app = XCUIApplication()
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
            XCUIApplication().launch()
        }
    }
}
