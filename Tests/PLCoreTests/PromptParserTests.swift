import XCTest
@testable import PLCore

final class PromptParserTests: XCTestCase {
    func testSplitsParagraphs() {
        let text = "First paragraph.\n\nSecond paragraph."
        let document = PromptParser.parse(text)
        XCTAssertEqual(document.blocks.count, 2)
        XCTAssertEqual(document.blocks[0].kind, .paragraph)
        XCTAssertEqual(document.blocks[1].lineRange, 3...3)
    }

    func testDetectsListItem() {
        let text = "- first item\n- second item"
        let document = PromptParser.parse(text)
        XCTAssertEqual(document.blocks.count, 1)
        XCTAssertEqual(document.blocks[0].kind, .listItem)
    }

    func testDetectsJSONFence() {
        let text = "```json\n{\"a\": 1}\n```"
        let document = PromptParser.parse(text)
        XCTAssertEqual(document.blocks.count, 1)
        XCTAssertEqual(document.blocks[0].kind, .jsonBlock)
    }

    func testDetectsCodeFenceWithLanguage() {
        let text = "```swift\nlet x = 1\n```"
        let document = PromptParser.parse(text)
        XCTAssertEqual(document.blocks.count, 1)
        XCTAssertEqual(document.blocks[0].kind, .codeBlock(language: "swift"))
    }
}
