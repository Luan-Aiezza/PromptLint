import Foundation

/// Abstrai onde o "último prompt desta sessão" é guardado, pra
/// `DuplicateContextRule` poder comparar contra o turno anterior sem saber
/// se o armazenamento é um arquivo, um banco, etc.
public protocol SessionStore {
    func loadLastPrompt(sessionID: String) throws -> String?
    func saveLastPrompt(sessionID: String, text: String) throws
}
