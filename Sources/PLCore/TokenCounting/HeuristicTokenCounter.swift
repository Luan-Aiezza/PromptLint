import Foundation

/// Estimativa offline e instantânea, sem chamar a API. Não é o tokenizer
/// real da Anthropic (que não é público) — serve para feedback rápido durante
/// a edição/lint de regras. A contagem final do relatório deve usar
/// `AnthropicTokenCounter` para um número exato.
public struct HeuristicTokenCounter: TokenCounter {
    public init() {}

    public func count(_ text: String) async throws -> Int {
        Self.estimate(text)
    }

    /// Varre o texto caractere a caractere: pontuação/símbolos contam como
    /// token próprio (como um BPE real costuma isolar), palavras quebram em
    /// ~4 caracteres por token, e espaços em branco são tratados como um
    /// separador único (grátis) só quando isolados — sequências (indentação,
    /// múltiplas linhas em branco) custam tokens de verdade, o que é o que
    /// permite detectar economia real ao compactar JSON/whitespace.
    public static func estimate(_ text: String) -> Int {
        guard !text.isEmpty else { return 0 }

        var tokenCount = 0
        var index = text.startIndex

        while index < text.endIndex {
            let character = text[index]

            if character.isWhitespace {
                var end = index
                while end < text.endIndex, text[end].isWhitespace {
                    end = text.index(after: end)
                }
                let length = text.distance(from: index, to: end)
                if length > 1 {
                    tokenCount += max(1, Int((Double(length) / 4.0).rounded(.up)))
                }
                index = end
                continue
            }

            if character.isPunctuation || character.isSymbol {
                tokenCount += 1
                index = text.index(after: index)
                continue
            }

            var end = index
            while end < text.endIndex, !text[end].isWhitespace, !text[end].isPunctuation, !text[end].isSymbol {
                end = text.index(after: end)
            }
            tokenCount += tokensForWord(length: text.distance(from: index, to: end))
            index = end
        }

        return tokenCount
    }

    private static func tokensForWord(length: Int) -> Int {
        guard length > 0 else { return 0 }
        return max(1, Int((Double(length) / 4.0).rounded(.up)))
    }
}
