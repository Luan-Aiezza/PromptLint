import XCTest
@testable import PLCore

final class RedundantInstructionRuleTests: XCTestCase {
    func testFlagsSimilarParagraphs() {
        let text = """
        Please review the code and point out all the bugs you find.

        Could you review the code and point out all the bugs found in it?
        """
        let document = PromptParser.parse(text)
        let findings = RedundantInstructionRule(similarityThreshold: 0.4).check(document)
        XCTAssertFalse(findings.isEmpty)
    }

    func testIgnoresUnrelatedParagraphs() {
        let text = """
        Review the code and point out bugs.

        Explain how the caching system works.
        """
        let document = PromptParser.parse(text)
        let findings = RedundantInstructionRule().check(document)
        XCTAssertTrue(findings.isEmpty)
    }
}
