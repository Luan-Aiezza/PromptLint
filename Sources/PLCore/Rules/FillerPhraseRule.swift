import Foundation

/// Detecta frases de enchimento comuns (PT-BR e EN) que não agregam
/// significado à instrução, mas custam tokens.
public struct FillerPhraseRule: LintRule {
    public let id = "filler-phrase"

    private static let phrases: [(pattern: String, suggestion: String)] = [
        ("eu gostaria que voc[eê] pudesse", "faça"),
        ("eu gostaria de pedir que voc[eê]", "faça"),
        ("por favor,? gentilmente", "por favor"),
        ("se poss[ií]vel,? por favor", ""),
        ("eu preciso que voc[eê]", "você deve"),
        ("i would like you to", "please"),
        ("if it'?s possible,? could you", "please"),
        ("i was wondering if you could", "please"),
        ("just to clarify,", ""),
    ]

    public init() {}

    public func check(_ document: PromptDocument) -> [Finding] {
        var findings: [Finding] = []
        for block in document.blocks {
            guard block.kind == .paragraph || block.kind == .listItem else { continue }
            for (pattern, suggestion) in Self.phrases {
                guard let range = block.text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) else {
                    continue
                }
                let matched = String(block.text[range])
                let savings = max(HeuristicTokenCounter.estimate(matched) - HeuristicTokenCounter.estimate(suggestion), 0)
                let messageSuffix = suggestion.isEmpty ? "" : " → sugestão: \"\(suggestion)\""
                findings.append(Finding(
                    ruleID: id,
                    message: "Frase de enchimento: \"\(matched)\"\(messageSuffix)",
                    lineRange: block.lineRange,
                    suggestedFix: suggestion.isEmpty ? nil : suggestion,
                    estimatedTokenSavings: savings
                ))
            }
        }
        return findings
    }
}
