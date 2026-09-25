import XCTest
@testable import PLCore

final class PricingTableTests: XCTestCase {
    func testComputesCostForKnownModel() {
        let cost = PricingTable.inputCostUSD(forTokens: 1_000_000, model: "claude-sonnet-5")
        XCTAssertEqual(cost, 2.0)
    }

    func testReturnsNilForUnknownModel() {
        let cost = PricingTable.inputCostUSD(forTokens: 1_000, model: "modelo-que-nao-existe")
        XCTAssertNil(cost)
    }

    func testOpusIsMoreExpensiveThanHaiku() {
        let opus = PricingTable.inputCostUSD(forTokens: 1_000, model: "claude-opus-5")!
        let haiku = PricingTable.inputCostUSD(forTokens: 1_000, model: "claude-haiku-4-5")!
        XCTAssertGreaterThan(opus, haiku)
    }
}
