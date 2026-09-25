public protocol LintRule {
    var id: String { get }
    func check(_ document: PromptDocument) -> [Finding]
}
