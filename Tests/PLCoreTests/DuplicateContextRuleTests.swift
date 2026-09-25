import XCTest
@testable import PLCore

final class DuplicateContextRuleTests: XCTestCase {
    func testFlagsBlockRepeatedFromPreviousTurn() {
        let previous = "Contexto do sistema que não muda entre turnos."
        let current = PromptParser.parse("Contexto do sistema que não muda entre turnos.\n\nNova pergunta do usuário.")

        let findings = DuplicateContextRule(previousText: previous).check(current)

        XCTAssertEqual(findings.count, 1)
        XCTAssertEqual(findings.first?.ruleID, "duplicate-context")
    }

    func testIgnoresWhenNoPreviousTurn() {
        let current = PromptParser.parse("Qualquer prompt novo, sem sessão anterior.")
        let findings = DuplicateContextRule(previousText: nil).check(current)
        XCTAssertTrue(findings.isEmpty)
    }

    func testIgnoresBlocksThatDidNotAppearBefore() {
        let previous = "Bloco A."
        let current = PromptParser.parse("Bloco totalmente diferente.")
        let findings = DuplicateContextRule(previousText: previous).check(current)
        XCTAssertTrue(findings.isEmpty)
    }
}
