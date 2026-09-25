import Foundation

public enum Severity: String {
    case info
    case warning
}

public struct Finding {
    public let ruleID: String
    public let message: String
    public let lineRange: ClosedRange<Int>
    public let severity: Severity
    public let suggestedFix: String?
    public let estimatedTokenSavings: Int

    public init(
        ruleID: String,
        message: String,
        lineRange: ClosedRange<Int>,
        severity: Severity = .warning,
        suggestedFix: String? = nil,
        estimatedTokenSavings: Int = 0
    ) {
        self.ruleID = ruleID
        self.message = message
        self.lineRange = lineRange
        self.severity = severity
        self.suggestedFix = suggestedFix
        self.estimatedTokenSavings = estimatedTokenSavings
    }
}
