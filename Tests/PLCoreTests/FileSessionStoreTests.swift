import XCTest
@testable import PLCore

final class FileSessionStoreTests: XCTestCase {
    private var tempDirectory: URL!
    private var store: FileSessionStore!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PromptLintTests-\(UUID().uuidString)", isDirectory: true)
        store = FileSessionStore(directory: tempDirectory)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    func testReturnsNilForUnknownSession() throws {
        let result = try store.loadLastPrompt(sessionID: "inexistente")
        XCTAssertNil(result)
    }

    func testSavesAndLoadsLastPrompt() throws {
        try store.saveLastPrompt(sessionID: "abc", text: "primeiro turno")
        let loaded = try store.loadLastPrompt(sessionID: "abc")
        XCTAssertEqual(loaded, "primeiro turno")
    }

    func testOverwritesPreviousPromptOnNewSave() throws {
        try store.saveLastPrompt(sessionID: "abc", text: "turno 1")
        try store.saveLastPrompt(sessionID: "abc", text: "turno 2")
        let loaded = try store.loadLastPrompt(sessionID: "abc")
        XCTAssertEqual(loaded, "turno 2")
    }

    func testSanitizesSessionIDToAvoidPathTraversal() throws {
        try store.saveLastPrompt(sessionID: "../../etc/passwd", text: "conteudo")
        let entries = try FileManager.default.contentsOfDirectory(atPath: tempDirectory.path)
        XCTAssertEqual(entries.count, 1)
        XCTAssertFalse(entries[0].contains("/"))
        XCTAssertFalse(entries[0].contains(".."))
    }
}
