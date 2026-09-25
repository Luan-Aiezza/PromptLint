import XCTest
@testable import PLCore

final class HeuristicTokenCounterTests: XCTestCase {
    func testEmptyTextIsZero() {
        XCTAssertEqual(HeuristicTokenCounter.estimate(""), 0)
    }

    func testPunctuationCountsAsOwnToken() {
        let withoutPunctuation = HeuristicTokenCounter.estimate("hello world")
        let withPunctuation = HeuristicTokenCounter.estimate("hello, world!")
        XCTAssertEqual(withPunctuation, withoutPunctuation + 2)
    }

    func testLongWordCostsMoreThanShortWord() {
        let short = HeuristicTokenCounter.estimate("hi")
        let long = HeuristicTokenCounter.estimate("supercalifragilisticexpialidocious")
        XCTAssertGreaterThan(long, short)
    }

    func testSingleSpaceBetweenWordsIsFree() {
        let separate = HeuristicTokenCounter.estimate("word1 word2")
        let concatenated = HeuristicTokenCounter.estimate("word1") + HeuristicTokenCounter.estimate("word2")
        XCTAssertEqual(separate, concatenated)
    }

    func testIndentationCostsMoreThanSingleSpace() {
        let indented = HeuristicTokenCounter.estimate("a\n        b")
        let singleSpace = HeuristicTokenCounter.estimate("a b")
        XCTAssertGreaterThan(indented, singleSpace)
    }
}
