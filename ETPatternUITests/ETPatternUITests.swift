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
        app.launchArguments = ["UITESTING"]
        app.launch()

        // Verify main screen elements
        XCTAssertTrue(app.staticTexts["English Thought"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["square.and.arrow.down"].exists)
        XCTAssertTrue(app.buttons["gear"].exists)
    }

    @MainActor
    func testDeckSelection() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITESTING"]
        app.launch()

        // Select first deck
        let firstDeck = app.buttons.matching(identifier: "DeckCard").element(boundBy: 0)
        XCTAssertTrue(firstDeck.waitForExistence(timeout: 10))
        firstDeck.tap()

        // Verify deck detail view
        XCTAssertTrue(app.navigationBars["ETPattern 300"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Study"].exists)
    }
}