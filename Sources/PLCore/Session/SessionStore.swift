import Foundation

/// Abstracts where "this session's last prompt" is stored, so
/// `DuplicateContextRule` can compare against the previous turn without
/// knowing whether the storage is a file, a database, etc.
public protocol SessionStore {
    func loadLastPrompt(sessionID: String) throws -> String?
    func saveLastPrompt(sessionID: String, text: String) throws
}
