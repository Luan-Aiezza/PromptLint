import Foundation

/// Guarda, por sessão, só o último prompt enviado — o suficiente pra
/// `DuplicateContextRule` comparar contra o turno anterior. Um arquivo texto
/// por sessão em `~/.promptlint/sessions/<id>.txt`; não precisa de um banco
/// porque não há histórico multi-turno a consultar, só o turno mais recente.
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
