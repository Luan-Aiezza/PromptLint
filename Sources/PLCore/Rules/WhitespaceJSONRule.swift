import Foundation

/// Flags "pretty" (indented) JSON blocks when a compact version would
/// represent the same content with fewer tokens.
public struct WhitespaceJSONRule: LintRule {
    public let id = "whitespace-json"

    public init() {}

    public func check(_ document: PromptDocument) -> [Finding] {
        var findings: [Finding] = []
        for block in document.blocks {
            guard block.kind == .jsonBlock else { continue }
            guard let data = block.text.data(using: .utf8),
                  let object = try? JSONSerialization.jsonObject(with: data) else { continue }
            guard let compactData = try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]),
                  let compact = String(data: compactData, encoding: .utf8) else { continue }
            guard compact.count < block.text.count else { continue }

            let savings = HeuristicTokenCounter.estimate(block.text) - HeuristicTokenCounter.estimate(compact)
            guard savings > 0 else { continue }

            findings.append(Finding(
                ruleID: id,
                message: "JSON block with unnecessary indentation/whitespace.",
                lineRange: block.lineRange,
                suggestedFix: compact,
                estimatedTokenSavings: savings
            ))
        }
        return findings
    }
}
