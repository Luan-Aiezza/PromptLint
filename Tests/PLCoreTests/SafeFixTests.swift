import XCTest
@testable import PLCore

final class SafeFixTests: XCTestCase {
    func testCompactsWhitespaceJSONBlock() {
        let text = """
        Analyze the payload below.

        ```json
        {
            "a": 1
        }
        ```
        """
        let document = PromptParser.parse(text)
        let findings = WhitespaceJSONRule().check(document)

        let fixed = SafeFix.apply(findings, to: text)

        XCTAssertTrue(fixed.contains(#"{"a":1}"#))
        XCTAssertFalse(fixed.contains("    \"a\": 1"))
    }

    func testRemovesDuplicateContextBlock() {
        let previous = "Fixed context that doesn't change."
        let current = "Fixed context that doesn't change.\n\nNew question."
        let document = PromptParser.parse(current)
        let findings = DuplicateContextRule(previousText: previous).check(document)

        let fixed = SafeFix.apply(findings, to: current)

        XCTAssertFalse(fixed.contains("Fixed context that doesn't change."))
        XCTAssertTrue(fixed.contains("New question."))
    }

    func testDoesNotTouchUnsafeFindings() {
        let text = "I would like you to please review this."
        let document = PromptParser.parse(text)
        let findings = FillerPhraseRule().check(document)

        let fixed = SafeFix.apply(findings, to: text)

        XCTAssertEqual(fixed, text)
    }

    func testIsSafeIdentifiesOnlyKnownRules() {
        let safeFinding = Finding(ruleID: "whitespace-json", message: "", lineRange: 1...1)
        let unsafeFinding = Finding(ruleID: "filler-phrase", message: "", lineRange: 1...1)

        XCTAssertTrue(SafeFix.isSafe(safeFinding))
        XCTAssertFalse(SafeFix.isSafe(unsafeFinding))
    }
}
