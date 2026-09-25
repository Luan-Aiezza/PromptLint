import Foundation

public struct PromptDocument {
    public let raw: String
    public let blocks: [Block]

    public init(raw: String, blocks: [Block]) {
        self.raw = raw
        self.blocks = blocks
    }
}
