import XCTest
@testable import PLCore

private actor CallCountingTokenCounter: TokenCounter {
    private(set) var callCount = 0

    func count(_ text: String) async throws -> Int {
        callCount += 1
        return text.count
    }
}

final class CachingTokenCounterTests: XCTestCase {
    func testReusesResultForSameText() async throws {
        let inner = CallCountingTokenCounter()
        let cache = CachingTokenCounter(wrapping: inner)

        let first = try await cache.count("mesmo texto")
        let second = try await cache.count("mesmo texto")

        XCTAssertEqual(first, second)
        let calls = await inner.callCount
        XCTAssertEqual(calls, 1)
    }

    func testDoesNotCacheAcrossDifferentTexts() async throws {
        let inner = CallCountingTokenCounter()
        let cache = CachingTokenCounter(wrapping: inner)

        _ = try await cache.count("texto a")
        _ = try await cache.count("texto b")

        let calls = await inner.callCount
        XCTAssertEqual(calls, 2)
    }
}
