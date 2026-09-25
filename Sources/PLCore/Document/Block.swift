import Foundation

public enum BlockKind: Equatable {
    case paragraph
    case listItem
    case codeBlock(language: String?)
    case jsonBlock
}

public struct Block: Equatable {
    public let kind: BlockKind
    public let text: String
    public let lineRange: ClosedRange<Int>

    public init(kind: BlockKind, text: String, lineRange: ClosedRange<Int>) {
        self.kind = kind
        self.text = text
        self.lineRange = lineRange
    }
}
