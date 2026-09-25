import Foundation

/// Decorator que memoiza a contagem por conteúdo exato do texto, para não
/// bater na API repetidamente para o mesmo trecho durante uma sessão de
/// lint iterativa. `actor` porque o cache é mutável e pode ser consultado
/// concorrentemente.
public actor CachingTokenCounter: TokenCounter {
    private let wrapped: TokenCounter
    private var cache: [String: Int] = [:]

    public init(wrapping tokenCounter: TokenCounter) {
        self.wrapped = tokenCounter
    }

    public func count(_ text: String) async throws -> Int {
        if let cached = cache[text] {
            return cached
        }
        let value = try await wrapped.count(text)
        cache[text] = value
        return value
    }
}
