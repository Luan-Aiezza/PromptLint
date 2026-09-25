import Foundation

/// Automatically applies only the fixes that carry no ambiguity of meaning:
/// compacting a JSON block and removing a block identical to one already
/// sent before. Phrase rewrites (filler, redundancy) are deliberately left
/// out — swapping words could change the meaning, and that requires human
/// review before applying.
public enum SafeFix {
    public static let ruleIDs: Set<String> = ["whitespace-json", "duplicate-context"]

    public static func isSafe(_ finding: Finding) -> Bool {
        ruleIDs.contains(finding.ruleID)
    }

    /// Rewrites the original text by applying the safe findings found.
    /// Findings are applied bottom-to-top (by line) so applying one doesn't
    /// invalidate the line indices of the ones not yet applied.
    public static func apply(_ findings: [Finding], to text: String) -> String {
        let safeFindings = findings
            .filter(isSafe)
            .sorted { $0.lineRange.lowerBound > $1.lineRange.lowerBound }

        var lines = text.components(separatedBy: "\n")

        for finding in safeFindings {
            let startIndex = finding.lineRange.lowerBound - 1
            let endIndex = min(finding.lineRange.upperBound, lines.count) - 1
            guard startIndex >= 0, startIndex <= endIndex, endIndex < lines.count else { continue }

            let replacement: [String]
            switch finding.ruleID {
            case "whitespace-json":
                guard let fix = finding.suggestedFix else { continue }
                replacement = ["```json", fix, "```"]
            default:
                replacement = []
            }

            lines.replaceSubrange(startIndex...endIndex, with: replacement)
        }

        return lines.joined(separator: "\n")
    }
}
