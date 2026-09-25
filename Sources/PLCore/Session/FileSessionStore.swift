import Foundation

/// Stores, per session, only the last prompt sent — enough for
/// `DuplicateContextRule` to compare against the previous turn. One text
/// file per session under `~/.promptlint/sessions/<id>.txt`; no database
/// needed since there's no multi-turn history to query, just the latest turn.
public struct FileSessionStore: SessionStore {
    private let directory: URL

    public init(directory: URL = FileSessionStore.defaultDirectory) {
        self.directory = directory
    }

    public static var defaultDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".promptlint/sessions", isDirectory: true)
    }

    public func loadLastPrompt(sessionID: String) throws -> String? {
        let url = fileURL(for: sessionID)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try String(contentsOf: url, encoding: .utf8)
    }

    public func saveLastPrompt(sessionID: String, text: String) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try text.write(to: fileURL(for: sessionID), atomically: true, encoding: .utf8)
    }

    private func fileURL(for sessionID: String) -> URL {
        directory.appendingPathComponent("\(sanitize(sessionID)).txt")
    }

    private func sanitize(_ sessionID: String) -> String {
        String(sessionID.map { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" ? $0 : "_" })
    }
}
