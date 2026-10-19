import XCTest

// Copied into an isolated project by scripts/iphone.py prepare-control.
// The config is base64 JSON, avoiding Swift code injection from bundle IDs.
final class FlightUITests: XCTestCase {
    struct Config: Decodable {
        let session: String
        let app: String
    }
    struct Action: Decodable {
        let session: String
        let id: Int
        let kind: String
        let text: String?
        let x: Double?
        let y: Double?
        let endX: Double?
        let endY: Double?
        let identifier: String?
        let bundle: String?
    }
    enum ControlError: Error { case invalidAction(String) }

    func testControlSession() throws {
        continueAfterFailure = false
        executionTimeAllowance = 2100
        let config = try JSONDecoder().decode(Config.self, from: Data(base64Encoded: "__CONFIG_BASE64__")!)
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let root = documents.appendingPathComponent("codex-" + config.session)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let marker = root.appendingPathComponent("claimed.txt")
        // A restarted test must never consume an old session again.
        guard !FileManager.default.fileExists(atPath: root.appendingPathComponent("started").path) else {
            throw ControlError.invalidAction("Session already started; prepare a fresh session")
        }
        try Data().write(to: root.appendingPathComponent("started"), options: .atomic)
        var app = XCUIApplication(bundleIdentifier: config.app)
        app.activate()
        try snapshot(app, id: 0, root: root, session: config.session)
        print("CODEX_CONTROL_READY \(config.session)")
        var lastID = 0
        let deadline = Date().addingTimeInterval(1800)
        while Date() < deadline {
            let file = root.appendingPathComponent("action.json")
            guard let data = try? Data(contentsOf: file),
                  let action = try? JSONDecoder().decode(Action.self, from: data),
                  action.session == config.session, action.id == lastID + 1 else {
                Thread.sleep(forTimeInterval: 0.25)
                continue
            }
            // Claim before acting: loss of an acknowledgement is never a reason to replay.
            lastID = action.id
            try String(lastID).write(to: marker, atomically: true, encoding: .utf8)
            do {
                try perform(action, app: &app)
                try snapshot(app, id: action.id, root: root, session: config.session)
            } catch {
                try result(id: action.id, root: root, session: config.session, status: "error", error: String(describing: error))
                throw error
            }
            if action.kind == "done" { return }
        }
        throw ControlError.invalidAction("Session expired after 30 minutes")
    }

    private func point(_ app: XCUIApplication, _ x: Double?, _ y: Double?) throws -> XCUICoordinate {
        guard let x = x, let y = y, x.isFinite, y.isFinite,
              x >= 0, y >= 0, x <= Double(app.frame.width), y <= Double(app.frame.height) else {
            throw ControlError.invalidAction("Coordinates must be inside the current app frame, in points")
        }
        return app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: x, dy: y))
    }
    private func perform(_ action: Action, app: inout XCUIApplication) throws {
        switch action.kind {
        case "snapshot", "done": break
        case "tap": try point(app, action.x, action.y).tap()
        case "drag":
            let start = try point(app, action.x, action.y)
            let end = try point(app, action.endX, action.endY)
            start.press(forDuration: 0.1, thenDragTo: end)
        case "tap-id":
            guard let identifier = action.identifier else { throw ControlError.invalidAction("Missing identifier") }
            let matches = app.descendants(matching: .any).matching(identifier: identifier)
            guard matches.count == 1, matches.element(boundBy: 0).isHittable else {
                throw ControlError.invalidAction("Identifier must resolve to exactly one hittable element")
            }
            matches.element(boundBy: 0).tap()
        case "type":
            guard let text = action.text, !text.isEmpty else { throw ControlError.invalidAction("Missing text") }
            app.typeText(text)
        case "activate":
            guard let bundle = action.bundle, !bundle.isEmpty else { throw ControlError.invalidAction("Missing bundle") }
            app = XCUIApplication(bundleIdentifier: bundle)
            app.activate()
        case "home": XCUIDevice.shared.press(.home)
        default: throw ControlError.invalidAction("Unknown kind")
        }
    }
    private func snapshot(_ app: XCUIApplication, id: Int, root: URL, session: String) throws {
        try app.debugDescription.write(to: root.appendingPathComponent("hierarchy-\(id).txt"), atomically: true, encoding: .utf8)
        // Save screenshot before acknowledgement, so a successful result is a complete observation.
        try XCUIScreen.main.screenshot().pngRepresentation.write(to: root.appendingPathComponent("screen-\(id).png"), options: .atomic)
        try result(id: id, root: root, session: session, status: "ok", error: "")
    }
    private func result(id: Int, root: URL, session: String, status: String, error: String) throws {
        let payload: [String: Any] = ["session": session, "id": id, "status": status, "error": error]
        try JSONSerialization.data(withJSONObject: payload).write(to: root.appendingPathComponent("result-\(id).json"), options: .atomic)
    }
}
