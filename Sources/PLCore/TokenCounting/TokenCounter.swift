import Foundation

/// Abstracts token counting so an offline estimate can later be swapped for
/// a real call to Anthropic's `count_tokens` endpoint (see
/// shared/token-counting.md) without changing the rest of the pipeline.
public protocol TokenCounter {
    func count(_ text: String) async throws -> Int
}
