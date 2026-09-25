import Foundation

/// Decorator that memoizes the count by the text's exact content, to avoid
/// hitting the API repeatedly for the same snippet during an iterative lint
/// session. An `actor` because the cache is mutable and may be accessed
/// concurrently.
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
