import Foundation

/// Offline, instant estimate, with no API call. This is not Anthropic's
/// real tokenizer (which isn't public) — it exists for fast feedback while
/// editing/linting rules. The report's final count should use
/// `AnthropicTokenCounter` for an exact number.
public struct HeuristicTokenCounter: TokenCounter {
    public init() {}

    public func count(_ text: String) async throws -> Int {
        Self.estimate(text)
    }

    /// Scans the text character by character: punctuation/symbols each count
    /// as their own token (the way a real BPE tends to isolate them), words
    /// break down at ~4 characters per token, and whitespace is treated as a
    /// single (free) separator only when isolated — runs of it (indentation,
    /// multiple blank lines) cost real tokens, which is what lets the tool
    /// detect real savings when compacting JSON/whitespace.
    public static func estimate(_ text: String) -> Int {
        guard !text.isEmpty else { return 0 }

        var tokenCount = 0
        var index = text.startIndex

        while index < text.endIndex {
            let character = text[index]

            if character.isWhitespace {
                var end = index
                while end < text.endIndex, text[end].isWhitespace {
                    end = text.index(after: end)
                }
                let length = text.distance(from: index, to: end)
                if length > 1 {
                    tokenCount += max(1, Int((Double(length) / 4.0).rounded(.up)))
                }
                index = end
                continue
            }

            if character.isPunctuation || character.isSymbol {
                tokenCount += 1
                index = text.index(after: index)
                continue
            }

            var end = index
            while end < text.endIndex, !text[end].isWhitespace, !text[end].isPunctuation, !text[end].isSymbol {
                end = text.index(after: end)
            }
            tokenCount += tokensForWord(length: text.distance(from: index, to: end))
            index = end
        }

        return tokenCount
    }

    private static func tokensForWord(length: Int) -> Int {
        guard length > 0 else { return 0 }
        return max(1, Int((Double(length) / 4.0).rounded(.up)))
    }
}
