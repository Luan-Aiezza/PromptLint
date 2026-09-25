import XCTest
@testable import PLCore

final class DuplicateContextRuleTests: XCTestCase {
    func testFlagsBlockRepeatedFromPreviousTurn() {
        let previous = "System context that doesn't change between turns."
        let current = PromptParser.parse("System context that doesn't change between turns.\n\nNew question from the user.")

        let findings = DuplicateContextRule(previousText: previous).check(current)

        XCTAssertEqual(findings.count, 1)
        XCTAssertEqual(findings.first?.ruleID, "duplicate-context")
    }

    func testIgnoresWhenNoPreviousTurn() {
        let current = PromptParser.parse("Any new prompt, with no previous session.")
        let findings = DuplicateContextRule(previousText: nil).check(current)
        XCTAssertTrue(findings.isEmpty)
    }

    func testIgnoresBlocksThatDidNotAppearBefore() {
        let previous = "Block A."
        let current = PromptParser.parse("A completely different block.")
        let findings = DuplicateContextRule(previousText: previous).check(current)
        XCTAssertTrue(findings.isEmpty)
    }
}
