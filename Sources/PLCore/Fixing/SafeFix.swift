import Foundation

/// Aplica automaticamente só as correções sem ambiguidade de significado:
/// compactar um bloco JSON e remover um bloco idêntico a um já enviado no
/// turno anterior. Reescrita de frases (filler, redundância) fica de fora de
/// propósito — trocar palavras pode mudar o sentido, e isso exige revisão
/// humana antes de aplicar.
public enum SafeFix {
    public static let ruleIDs: Set<String> = ["whitespace-json", "duplicate-context"]

    public static func isSafe(_ finding: Finding) -> Bool {
        ruleIDs.contains(finding.ruleID)
    }

    /// Reescreve o texto original aplicando as correções seguras encontradas.
    /// Findings são aplicados de baixo para cima (por linha) para não invalidar
    /// os índices de linha das correções ainda não aplicadas.
    public static func apply(_ findings: [Finding], to text: String) -> String {
        let safeFindings = findings
            .filter(isSafe)
            .sorted { $0.lineRange.lowerBound > $1.lineRange.lowerBound }

        var lines = text.components(separatedBy: "\n")

        for finding in safeFindings {
            let startIndex = finding.lineRange.lowerBound - 1
            let endIndex = min(finding.lineRange.upperBound, lines.count) - 1
            guard startIndex >= 0, startIndex <= endIndex, endIndex < lines.count else { continue }

            let replacement: [String]
            switch finding.ruleID {
            case "whitespace-json":
                guard let fix = finding.suggestedFix else { continue }
                replacement = ["```json", fix, "```"]
            default:
                replacement = []
            }

            lines.replaceSubrange(startIndex...endIndex, with: replacement)
        }

        return lines.joined(separator: "\n")
    }
}
