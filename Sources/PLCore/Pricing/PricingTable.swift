import Foundation

public struct ModelPricing {
    public let inputPerMillionUSD: Double
    public let outputPerMillionUSD: Double
}

/// Current Anthropic API prices (per million tokens). Only the input price
/// matters here, since what PromptLint estimates is prompt cost (input
/// tokens), not response cost.
public enum PricingTable {
    public static let models: [String: ModelPricing] = [
        "claude-opus-5": ModelPricing(inputPerMillionUSD: 5, outputPerMillionUSD: 25),
        "claude-sonnet-5": ModelPricing(inputPerMillionUSD: 2, outputPerMillionUSD: 10),
        "claude-haiku-4-5": ModelPricing(inputPerMillionUSD: 1, outputPerMillionUSD: 5),
    ]

    public static func inputCostUSD(forTokens tokens: Int, model: String) -> Double? {
        guard let pricing = models[model] else { return nil }
        return Double(tokens) * pricing.inputPerMillionUSD / 1_000_000
    }
}
