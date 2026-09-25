import Foundation

public struct LintReport {
    public let originalTokens: Int
    public let findings: [Finding]
    public let model: String

    public init(originalTokens: Int, findings: [Finding], model: String) {
        self.originalTokens = originalTokens
        self.findings = findings
        self.model = model
    }

    public var potentialSavings: Int {
        findings.reduce(0) { $0 + $1.estimatedTokenSavings }
    }

    public var estimatedTokensAfterFixes: Int {
        max(originalTokens - potentialSavings, 0)
    }

    public var originalCostUSD: Double? {
        PricingTable.inputCostUSD(forTokens: originalTokens, model: model)
    }

    public var potentialSavingsUSD: Double? {
        PricingTable.inputCostUSD(forTokens: potentialSavings, model: model)
    }
}

public enum ConsoleReporter {
    public static func render(_ report: LintReport) -> String {
        var lines: [String] = []
        lines.append("Current tokens (estimate): \(report.originalTokens)\(costSuffix(report.originalCostUSD, model: report.model))")

        guard !report.findings.isEmpty else {
            lines.append("No issues found.")
            return lines.joined(separator: "\n")
        }

        let percent = report.originalTokens > 0
            ? Int((Double(report.potentialSavings) / Double(report.originalTokens)) * 100)
            : 0
        lines.append("Potential savings: \(report.potentialSavings) tokens (-\(percent)%)\(costSuffix(report.potentialSavingsUSD, model: report.model))")
        lines.append("")

        for finding in report.findings {
            lines.append("⚠ Lines \(finding.lineRange.lowerBound)-\(finding.lineRange.upperBound) [\(finding.ruleID)]\(SafeFix.isSafe(finding) ? " [auto-fix available: --fix]" : "")")
            lines.append("   \(finding.message)")
            if let fix = finding.suggestedFix {
                lines.append("   → suggestion: \(fix)")
            }
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    private static func costSuffix(_ value: Double?, model: String) -> String {
        guard let value else { return "" }
        return String(format: " (~US$ %.6f on %@)", value, model)
    }
}
