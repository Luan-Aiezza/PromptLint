import Foundation

/// Divide um prompt em blocos (parágrafos, itens de lista, código, JSON),
/// preservando a linha de origem de cada trecho para que regras e relatórios
/// possam apontar a localização exata do problema.
public enum PromptParser {
    public static func parse(_ raw: String) -> PromptDocument {
        let lines = raw.components(separatedBy: "\n")
        var blocks: [Block] = []

        var index = 0
        var paragraphLines: [String] = []
        var paragraphStart = 1

        func flushParagraph(endLine: Int) {
            guard !paragraphLines.isEmpty else { return }
            let text = paragraphLines.joined(separator: "\n")
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                let kind: BlockKind = isListItem(trimmed) ? .listItem : .paragraph
                blocks.append(Block(kind: kind, text: text, lineRange: paragraphStart...max(paragraphStart, endLine)))
            }
            paragraphLines = []
        }

        while index < lines.count {
            let lineNumber = index + 1
            let line = lines[index]

            if let language = fenceLanguage(of: line) {
                flushParagraph(endLine: lineNumber - 1)

                let codeStart = lineNumber
                var codeLines: [String] = []
                index += 1
                while index < lines.count, !isFence(lines[index]) {
                    codeLines.append(lines[index])
                    index += 1
                }
                let codeEnd = min(index + 1, lines.count)
                let codeText = codeLines.joined(separator: "\n")
                let kind: BlockKind = language.lowercased() == "json"
                    ? .jsonBlock
                    : .codeBlock(language: language.isEmpty ? nil : language)
                blocks.append(Block(kind: kind, text: codeText, lineRange: codeStart...max(codeStart, codeEnd)))

                if index < lines.count { index += 1 } // pula a cerca de fechamento ```
                paragraphStart = index + 1
                continue
            }

            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                flushParagraph(endLine: lineNumber - 1)
                paragraphStart = lineNumber + 1
            } else {
                if paragraphLines.isEmpty {
                    paragraphStart = lineNumber
                }
                paragraphLines.append(line)
            }
            index += 1
        }
        flushParagraph(endLine: lines.count)

        return PromptDocument(raw: raw, blocks: blocks)
    }

    private static func fenceLanguage(of line: String) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("```") else { return nil }
        return String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
    }

    private static func isFence(_ line: String) -> Bool {
        line.trimmingCharacters(in: .whitespaces).hasPrefix("```")
    }

    private static func isListItem(_ text: String) -> Bool {
        let markers = ["- ", "* ", "+ "]
        if markers.contains(where: { text.hasPrefix($0) }) { return true }
        guard let firstLine = text.components(separatedBy: "\n").first else { return false }
        return firstLine.range(of: #"^\d+[.)]\s"#, options: .regularExpression) != nil
    }
}
