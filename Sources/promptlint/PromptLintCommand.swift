import ArgumentParser
import Foundation
import PLCore

@main
struct PromptLint: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "promptlint",
        abstract: "Analyzes prompts and suggests token reductions.",
        subcommands: [Check.self, Fix.self],
        defaultSubcommand: Check.self
    )
}

/// Applies the safe fixes and prints only the resulting text, with no
/// report — meant for composition in scripts/shell wrappers (e.g.
/// `text=$(promptlint fix - <<< "$text")`), not for interactive use. Only
/// covers rules that don't depend on a session (today, `whitespace-json`);
/// `duplicate-context` is left out because it would also require managing
/// session history here, which would remove the simplicity this one-line
/// composition relies on.
struct Fix: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "fix",
        abstract: "Applies the safe fixes and prints only the resulting text (for use in scripts)."
    )

    @Argument(help: "Path to the file. Omit or use '-' to read from standard input.")
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
        abstract: "Analyzes a file (or stdin) and reports token-reduction opportunities."
    )

    @Argument(help: "Path to the file to analyze. Omit or use '-' to read from standard input.")
    var path: String?

    @Flag(name: .long, help: "Uses the exact count from the API (count_tokens endpoint) instead of the offline estimate.")
    var exact = false

    @Option(name: .long, help: "Model used for exact counting (--exact) and to estimate cost in USD.")
    var model = "claude-sonnet-5"

    @Option(name: .long, help: "Anthropic API key. If omitted, falls back to the ANTHROPIC_API_KEY environment variable.")
    var apiKey: String?

    @Option(name: .long, help: "Chat session identifier, used to detect repeated context across turns.")
    var session: String?

    @Flag(name: .long, help: "Automatically applies the safe fixes (compacted JSON, duplicate context removed).")
    var fix = false

    @Flag(name: .long, help: "Emits the report as JSON instead of human-readable text (useful for scripts/CI).")
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

    /// Computes the fixed text and, if an input file was given (not stdin),
    /// already writes the fix to disk. Prints nothing — the caller decides
    /// the output format (text or JSON).
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
            print("\nNo safe fix to apply automatically.")
            return
        }
        if let writtenToFile = fixInfo.writtenToFile {
            print("\n✅ \(fixInfo.safeFixCount) safe fix(es) applied to \(writtenToFile).")
        } else if let fixedText = fixInfo.fixedText {
            print("\n--- Fixed text (\(fixInfo.safeFixCount) safe fix(es) applied) ---")
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
