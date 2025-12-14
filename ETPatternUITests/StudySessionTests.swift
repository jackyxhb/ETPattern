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
        let firstDeckCell = app.tables.cells.element(boundBy: 0)
        XCTAssertTrue(firstDeckCell.waitForExistence(timeout: 5), "Deck list is empty")
        firstDeckCell.tap()

        let studyButton = app.buttons["Study"]
        XCTAssertTrue(studyButton.waitForExistence(timeout: 5))
        studyButton.tap()
    }

    @MainActor
    func testAgainAndEasyButtonsExist() throws {
        let app = XCUIApplication()
        app.launch()
        startStudySession(app: app)

        let againButton = app.buttons["Again"]
        let easyButton = app.buttons["Easy"]
        XCTAssertTrue(againButton.waitForExistence(timeout: 5))
        XCTAssertTrue(easyButton.waitForExistence(timeout: 5))

        againButton.tap()
        easyButton.tap()

        XCTAssertTrue(app.navigationBars["Study Session"].exists || app.staticTexts["Session Complete!"].exists)
    }

    @MainActor
    func testNavigationShortcuts() throws {
        let app = XCUIApplication()
        app.launch()

        let statsButton = app.buttons["chart.bar"]
        XCTAssertTrue(statsButton.exists)
        statsButton.tap()
        XCTAssertTrue(app.navigationBars["Study Sessions"].waitForExistence(timeout: 3))
        app.buttons["Done"].tap()

        let importButton = app.buttons["square.and.arrow.down"]
        XCTAssertTrue(importButton.exists)
        importButton.tap()
        XCTAssertTrue(app.staticTexts["Import CSV File"].waitForExistence(timeout: 3))
        app.navigationBars.buttons["Back"].tap()

    @MainActor
    func testSessionCompletionFlow() throws {
        let app = XCUIApplication()
        app.launch()
        startStudySession(app: app)

        // Assume there are cards to review. Swipe through all cards to complete session
        var cardCount = 0
        while app.staticTexts["Session Complete!"].waitForExistence(timeout: 2) == false && cardCount < 10 {
            let card = app.otherElements.element(boundBy: 0)
            if card.exists {
                card.swipeRight() // Easy
                cardCount += 1
            } else {
                break
            }
        }

        // Check if session completes
        let completionText = app.staticTexts["Session Complete!"]
        XCTAssertTrue(completionText.waitForExistence(timeout: 5), "Session should complete after reviewing cards")

        // Check completion details
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Cards Reviewed")).element.exists)
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Correct Answers")).element.exists)
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Accuracy")).element.exists)

        // Tap Done to return
        let doneButton = app.buttons["Done"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 5))
        doneButton.tap()

        // Should return to deck list
        XCTAssertTrue(app.navigationBars["Decks"].waitForExistence(timeout: 5))
    }
