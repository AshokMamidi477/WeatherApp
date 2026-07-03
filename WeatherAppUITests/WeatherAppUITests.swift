import XCTest

final class WeatherAppUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testSearchFieldAndButtonExist() throws {
        let app = XCUIApplication()
        app.launchArguments += ["UI_TESTING"]
        app.launch()

        XCTAssertTrue(app.textFields["City search field"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Search weather"].exists)
    }

    @MainActor
    func testEmptySearchShowsPlaceholderGuidance() throws {
        let app = XCUIApplication()
        app.launchArguments += ["UI_TESTING"]
        app.launch()

        app.buttons["Search weather"].tap()
        XCTAssertTrue(app.staticTexts["Please enter a US city name."].waitForExistence(timeout: 3))
    }
}
