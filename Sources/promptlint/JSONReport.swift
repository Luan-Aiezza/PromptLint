import Foundation
import PLCore

/// Serializable representation of the report, for consumption by scripts/CI
/// via `--json`. Lives in the CLI (not in PLCore) because it's a
/// consumer-specific output format, not part of the linter's domain.
struct JSONFinding: Encodable {
    let ruleID: String
    let message: String
    let startLine: Int
    let endLine: Int
    let suggestedFix: String?
    let estimatedTokenSavings: Int
    let autoFixable: Bool

    init(_ finding: Finding) {
        ruleID = finding.ruleID
        message = finding.message
        startLine = finding.lineRange.lowerBound
        endLine = finding.lineRange.upperBound
        suggestedFix = finding.suggestedFix
        estimatedTokenSavings = finding.estimatedTokenSavings
        autoFixable = SafeFix.isSafe(finding)
    }
}

struct JSONFixInfo: Encodable {
    let safeFixCount: Int
    let changed: Bool
    let writtenToFile: String?
    let fixedText: String?
}

struct JSONReport: Encodable {
    let model: String
    let originalTokens: Int
    let originalCostUSD: Double?
    let potentialSavings: Int
    let potentialSavingsUSD: Double?
    let findings: [JSONFinding]
    let fix: JSONFixInfo?

    init(_ report: LintReport, fix: JSONFixInfo?) {
        model = report.model
        originalTokens = report.originalTokens
        originalCostUSD = report.originalCostUSD
        potentialSavings = report.potentialSavings
        potentialSavingsUSD = report.potentialSavingsUSD
        findings = report.findings.map(JSONFinding.init)
        self.fix = fix
    }
}
