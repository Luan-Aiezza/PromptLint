import XCTest
@testable import PLCore

final class SafeFixTests: XCTestCase {
    func testCompactsWhitespaceJSONBlock() {
        let text = """
        Analise o payload abaixo.

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
        let previous = "Contexto fixo que não muda."
        let current = "Contexto fixo que não muda.\n\nPergunta nova."
        let document = PromptParser.parse(current)
        let findings = DuplicateContextRule(previousText: previous).check(document)

        let fixed = SafeFix.apply(findings, to: current)

        XCTAssertFalse(fixed.contains("Contexto fixo que não muda."))
        XCTAssertTrue(fixed.contains("Pergunta nova."))
    }

    func testDoesNotTouchUnsafeFindings() {
        let text = "Eu gostaria que você pudesse revisar isso."
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
