import ArgumentParser
import Foundation
import PLCore

@main
struct PromptLint: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "promptlint",
        abstract: "Analisa prompts e sugere reduções de tokens.",
        subcommands: [Check.self, Fix.self],
        defaultSubcommand: Check.self
    )
}

/// Aplica as correções seguras e imprime só o texto resultante, sem
/// relatório — pensado pra composição em scripts/wrappers de shell
/// (ex: `texto=$(promptlint fix - <<< "$texto")`), não pra uso interativo.
/// Só cobre regras que não dependem de sessão (hoje, `whitespace-json`);
/// `duplicate-context` fica de fora porque exigiria também gerenciar o
/// histórico de sessão aqui, o que remove a simplicidade que essa
/// composição em uma linha depende.
struct Fix: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "fix",
        abstract: "Aplica as correções seguras e imprime só o texto resultante (uso em scripts)."
    )

    @Argument(help: "Caminho do arquivo. Omita ou use '-' para ler da entrada padrão.")
    var path: String?

    func run() throws {
        let text = try readInput(path: path)
        let document = PromptParser.parse(text)
        let findings = Linter.defaultRules.flatMap { $0.check(document) }
        let fixedText = SafeFix.apply(findings, to: text)
        print(fixedText, terminator: "")
    }
}

struct Check: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "check",
        abstract: "Analisa um arquivo (ou stdin) e reporta oportunidades de redução de tokens."
    )

    @Argument(help: "Caminho do arquivo a analisar. Omita ou use '-' para ler da entrada padrão.")
    var path: String?

    @Flag(name: .long, help: "Usa a contagem exata da API (endpoint count_tokens) em vez da estimativa offline.")
    var exact = false

    @Option(name: .long, help: "Modelo usado para a contagem exata (--exact) e para estimar custo em USD.")
    var model = "claude-sonnet-5"

    @Option(name: .long, help: "Chave de API da Anthropic. Se omitida, usa a variável de ambiente ANTHROPIC_API_KEY.")
    var apiKey: String?

    @Option(name: .long, help: "Identificador de sessão de chat, para detectar contexto repetido entre turnos.")
    var session: String?

    @Flag(name: .long, help: "Aplica automaticamente as correções seguras (JSON compactado, contexto duplicado removido).")
    var fix = false

    @Flag(name: .long, help: "Emite o relatório em JSON em vez de texto legível (útil para scripts/CI).")
    var json = false

    func run() async throws {
        let text = try readInput(path: path)
        let sessionStore = FileSessionStore()

        var rules = Linter.defaultRules
        if let session {
            let previous = try sessionStore.loadLastPrompt(sessionID: session)
            rules.append(DuplicateContextRule(previousText: previous))
        }

        let report = try await Linter(rules: rules, tokenCounter: try makeTokenCounter(), model: model).lint(text)
        let fixInfo = fix ? try applyFixIfNeeded(using: report.findings, originalText: text) : nil

        if json {
            try printJSON(report: report, fixInfo: fixInfo)
        } else {
            print(ConsoleReporter.render(report))
            if let fixInfo {
                printFixSummary(fixInfo)
            }
        }

        if let session {
            try sessionStore.saveLastPrompt(sessionID: session, text: text)
        }
    }

    /// Calcula o texto corrigido e, se um arquivo de entrada foi informado
    /// (não stdin), já grava a correção em disco. Não imprime nada — quem
    /// chama decide o formato de saída (texto ou JSON).
    private func applyFixIfNeeded(using findings: [Finding], originalText: String) throws -> JSONFixInfo {
        let fixedText = SafeFix.apply(findings, to: originalText)
        let safeCount = findings.filter(SafeFix.isSafe).count
        let changed = fixedText != originalText

        guard changed, let path, path != "-" else {
            return JSONFixInfo(
                safeFixCount: safeCount,
                changed: changed,
                writtenToFile: nil,
                fixedText: changed ? fixedText : nil
            )
        }

        try fixedText.write(toFile: path, atomically: true, encoding: .utf8)
        return JSONFixInfo(safeFixCount: safeCount, changed: true, writtenToFile: path, fixedText: nil)
    }

    private func printFixSummary(_ fixInfo: JSONFixInfo) {
        guard fixInfo.changed else {
            print("\nNenhuma correção segura para aplicar automaticamente.")
            return
        }
        if let writtenToFile = fixInfo.writtenToFile {
            print("\n✅ \(fixInfo.safeFixCount) correção(ões) segura(s) aplicada(s) em \(writtenToFile).")
        } else if let fixedText = fixInfo.fixedText {
            print("\n--- Texto corrigido (\(fixInfo.safeFixCount) correção(ões) segura(s) aplicada(s)) ---")
            print(fixedText)
        }
    }

    private func printJSON(report: LintReport, fixInfo: JSONFixInfo?) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(JSONReport(report, fix: fixInfo))
        print(String(decoding: data, as: UTF8.self))
    }

    private func makeTokenCounter() throws -> TokenCounter {
        guard exact else { return HeuristicTokenCounter() }
        guard let key = apiKey ?? ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"], !key.isEmpty else {
            throw AnthropicTokenCounterError.missingAPIKey
        }
        return CachingTokenCounter(wrapping: AnthropicTokenCounter(model: model, apiKey: key))
    }
}
