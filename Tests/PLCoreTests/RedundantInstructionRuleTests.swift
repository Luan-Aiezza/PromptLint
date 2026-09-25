import XCTest
@testable import PLCore

final class RedundantInstructionRuleTests: XCTestCase {
    func testFlagsSimilarParagraphs() {
        let text = """
        Por favor revise o código e aponte todos os bugs encontrados.

        Poderia revisar o código e apontar todos os bugs encontrados nele?
        """
        let document = PromptParser.parse(text)
        let findings = RedundantInstructionRule(similarityThreshold: 0.4).check(document)
        XCTAssertFalse(findings.isEmpty)
    }

    func testIgnoresUnrelatedParagraphs() {
        let text = """
        Revise o código e aponte bugs.

        Explique como funciona o sistema de cache.
        """
        let document = PromptParser.parse(text)
        let findings = RedundantInstructionRule().check(document)
        XCTAssertTrue(findings.isEmpty)
    }
}
