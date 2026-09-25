import XCTest
@testable import PLCore

final class FillerPhraseRuleTests: XCTestCase {
    func testDetectsFillerPhrase() {
        let text = "Eu gostaria que você pudesse revisar este código."
        let document = PromptParser.parse(text)
        let findings = FillerPhraseRule().check(document)
        XCTAssertFalse(findings.isEmpty)
    }

    func testIgnoresCleanText() {
        let text = "Revise este código e aponte bugs."
        let document = PromptParser.parse(text)
        let findings = FillerPhraseRule().check(document)
        XCTAssertTrue(findings.isEmpty)
    }
}
