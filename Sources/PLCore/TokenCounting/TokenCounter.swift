import Foundation

/// Abstrai a contagem de tokens para permitir trocar, no futuro, uma
/// estimativa offline por uma chamada real ao endpoint `count_tokens`
/// da Anthropic (ver shared/token-counting.md) sem alterar o restante do pipeline.
public protocol TokenCounter {
    func count(_ text: String) async throws -> Int
}
