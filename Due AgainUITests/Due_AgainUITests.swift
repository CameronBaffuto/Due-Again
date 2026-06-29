import XCTest

final class DueAgainUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testEmptyStateRenders() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITestMode"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Due Today"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Never wonder when you last did it."].exists)
    }

    func testAddTaskFlowCreatesTask() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITestMode"]
        app.launch()

        app.buttons["Add cadence"].tap()

        let titleField = app.textFields["task-title"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        titleField.tap()
        titleField.typeText("Water cactus")

        app.buttons["save-task"].tap()

        XCTAssertTrue(app.staticTexts["Water cactus"].waitForExistence(timeout: 5))
    }
}
