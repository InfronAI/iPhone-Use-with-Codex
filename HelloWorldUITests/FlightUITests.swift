import XCTest

final class FlightUITests: XCTestCase {
    func testFlightControlsAndLifecycleOnDevice() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["startGame"].waitForExistence(timeout: 10))
        capture(app, name: "01-launch-screen")
        app.buttons["startGame"].tap()
        XCTAssertTrue(app.buttons["pauseGame"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["useBomb"].label.contains("3"))

        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.72))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.25, dy: 0.65))
        start.press(forDuration: 0.05, thenDragTo: end)
        app.buttons["useBomb"].tap()
        XCTAssertTrue(app.buttons["useBomb"].label.contains("2"))
        capture(app, name: "02-combat")
        app.buttons["pauseGame"].tap()
        XCTAssertTrue(app.buttons["resumeGame"].waitForExistence(timeout: 3))
        capture(app, name: "03-paused")
        app.buttons["restartGame"].tap()
        XCTAssertTrue(app.buttons["useBomb"].label.contains("3"), "Restart restores bombs")

        // Switching apps gives a verifiable background transition on this device;
        // its synthetic Home-button event does not leave the foreground app.
        XCUIApplication(bundleIdentifier: "com.apple.Preferences").activate()
        XCTAssertTrue(app.wait(for: .runningBackground, timeout: 5) || app.state == .runningBackgroundSuspended,
                      "App must actually enter the background before returning")
        app.activate()
        XCTAssertTrue(app.buttons["resumeGame"].waitForExistence(timeout: 5), "Backgrounding pauses the battle")
        app.buttons["resumeGame"].tap()
        XCTAssertTrue(app.buttons["pauseGame"].waitForExistence(timeout: 3))
        app.buttons["pauseGame"].tap()
        XCTAssertTrue(app.buttons["resumeGame"].exists)
    }

    private func capture(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
