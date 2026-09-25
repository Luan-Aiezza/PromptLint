import Foundation

/// Compara parágrafos entre si (similaridade de Jaccard sobre palavras) para
/// achar instruções repetidas dentro do mesmo prompt.
public struct RedundantInstructionRule: LintRule {
    public let id = "redundant-instruction"
    private let similarityThreshold: Double

    public init(similarityThreshold: Double = 0.6) {
        self.similarityThreshold = similarityThreshold
    }

    public func check(_ document: PromptDocument) -> [Finding] {
        let paragraphs = document.blocks.filter { $0.kind == .paragraph }
        guard paragraphs.count > 1 else { return [] }

        var findings: [Finding] = []
        var flagged = Set<Int>()

        for i in 0..<paragraphs.count {
            guard !flagged.contains(i) else { continue }
            for j in (i + 1)..<paragraphs.count {
                guard !flagged.contains(j) else { continue }
                let similarity = jaccard(paragraphs[i].text, paragraphs[j].text)
                guard similarity >= similarityThreshold else { continue }

                flagged.insert(j)
                let savings = HeuristicTokenCounter.estimate(paragraphs[j].text)
                let firstRange = paragraphs[i].lineRange
                findings.append(Finding(
                    ruleID: id,
                    message: "Instrução parecida com o bloco nas linhas \(firstRange.lowerBound)-\(firstRange.upperBound) (similaridade \(Int(similarity * 100))%).",
                    lineRange: paragraphs[j].lineRange,
                    estimatedTokenSavings: savings
                ))
            }
        }
        return findings
    }

    private func jaccard(_ a: String, _ b: String) -> Double {
        let setA = Set(words(of: a))
        let setB = Set(words(of: b))
        guard !setA.isEmpty, !setB.isEmpty else { return 0 }
        let intersection = setA.intersection(setB).count
        let union = setA.union(setB).count
        return union == 0 ? 0 : Double(intersection) / Double(union)
    }

    private func words(of text: String) -> [String] {
        text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
    }
}
