import Foundation

/// Compara os blocos do prompt atual contra o prompt anterior da mesma
/// sessão (carregado pela CLI e injetado aqui) para achar contexto repetido
/// entre turnos — o caso mais valioso de economia em apps de chat, já que
/// reenviar o mesmo bloco de sistema/contexto a cada turno cobra tokens de
/// novo. Comparação é por igualdade exata de bloco, não similaridade — um
/// bloco reenviado palavra por palavra é o caso claro e sem falso positivo.
public struct DuplicateContextRule: LintRule {
    public let id = "duplicate-context"
    private let previousBlockTexts: Set<String>

    public init(previousText: String?) {
        guard let previousText else {
            self.previousBlockTexts = []
            return
        }
        self.previousBlockTexts = Set(PromptParser.parse(previousText).blocks.map { $0.text })
    }

    public func check(_ document: PromptDocument) -> [Finding] {
        guard !previousBlockTexts.isEmpty else { return [] }

        var findings: [Finding] = []
        for block in document.blocks {
            guard previousBlockTexts.contains(block.text) else { continue }
            findings.append(Finding(
                ruleID: id,
                message: "Bloco idêntico a um já enviado no turno anterior desta sessão.",
                lineRange: block.lineRange,
                estimatedTokenSavings: HeuristicTokenCounter.estimate(block.text)
            ))
        }
        return findings
    }
}
