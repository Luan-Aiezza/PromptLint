import XCTest
@testable import PLCore

final class LinterTests: XCTestCase {
    func testLintProducesReportWithSavings() async throws {
        let text = "I would like you to please review this code and point out bugs."
        let report = try await Linter().lint(text)
        XCTAssertGreaterThan(report.originalTokens, 0)
        XCTAssertFalse(report.findings.isEmpty)
        XCTAssertLessThan(report.estimatedTokensAfterFixes, report.originalTokens)
    }
}
