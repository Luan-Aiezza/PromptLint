import Foundation

/// Compares the current prompt's blocks against the previous prompt of the
/// same session (loaded by the CLI and injected here) to find repeated
/// context across turns — the most valuable savings case in chat apps,
/// since resending the same system/context block every turn costs tokens
/// all over again. Comparison is exact block equality, not similarity — a
/// block resent word-for-word is the clear, false-positive-free case.
public struct DuplicateContextRule: LintRule {
    public let id = "duplicate-context"
    private let previousBlockTexts: Set<String>

    public init(previousText: String?) {
        guard let previousText else {
            self.previousBlockTexts = []
            return
        }
        self.previousBlockTexts = Set(PromptParser.parse(previousText).blocks.map { $0.text })
    }

    public func check(_ document: PromptDocument) -> [Finding] {
        guard !previousBlockTexts.isEmpty else { return [] }

        var findings: [Finding] = []
        for block in document.blocks {
            guard previousBlockTexts.contains(block.text) else { continue }
            findings.append(Finding(
                ruleID: id,
                message: "Block identical to one already sent in the previous turn of this session.",
                lineRange: block.lineRange,
                estimatedTokenSavings: HeuristicTokenCounter.estimate(block.text)
            ))
        }
        return findings
    }
}
