import XCTest
@testable import PLCore

final class WhitespaceJSONRuleTests: XCTestCase {
    func testFlagsPrettyPrintedJSON() {
        let text = """
        ```json
        {
            "name": "test",
            "value": 123
        }
        ```
        """
        let document = PromptParser.parse(text)
        let findings = WhitespaceJSONRule().check(document)
        XCTAssertFalse(findings.isEmpty)
    }

    func testIgnoresAlreadyCompactJSON() {
        let text = "```json\n{\"name\":\"test\",\"value\":123}\n```"
        let document = PromptParser.parse(text)
        let findings = WhitespaceJSONRule().check(document)
        XCTAssertTrue(findings.isEmpty)
    }
}
