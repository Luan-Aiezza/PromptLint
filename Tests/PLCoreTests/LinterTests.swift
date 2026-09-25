import XCTest
@testable import PLCore

final class LinterTests: XCTestCase {
    func testLintProducesReportWithSavings() async throws {
        let text = "Eu gostaria que você pudesse revisar este código e apontar bugs."
        let report = try await Linter().lint(text)
        XCTAssertGreaterThan(report.originalTokens, 0)
        XCTAssertFalse(report.findings.isEmpty)
        XCTAssertLessThan(report.estimatedTokensAfterFixes, report.originalTokens)
    }
}
