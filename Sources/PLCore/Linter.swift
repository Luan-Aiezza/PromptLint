import Foundation

/// Ponto de entrada da biblioteca: junta parsing, regras e contagem de
/// tokens num único fluxo. A CLI (alvo `promptlint`) só chama isto.
public struct Linter {
    private let rules: [LintRule]
    private let tokenCounter: TokenCounter
    private let model: String

    public init(
        rules: [LintRule] = Linter.defaultRules,
        tokenCounter: TokenCounter = HeuristicTokenCounter(),
        model: String = "claude-sonnet-5"
    ) {
        self.rules = rules
        self.tokenCounter = tokenCounter
        self.model = model
    }

    public static var defaultRules: [LintRule] {
        [FillerPhraseRule(), RedundantInstructionRule(), WhitespaceJSONRule()]
    }

    public func lint(_ text: String) async throws -> LintReport {
        let document = PromptParser.parse(text)
        let originalTokens = try await tokenCounter.count(text)
        let findings = rules.flatMap { $0.check(document) }
        return LintReport(originalTokens: originalTokens, findings: findings, model: model)
    }
}
