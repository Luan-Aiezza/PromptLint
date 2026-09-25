import Foundation

/// Reads the text to analyze from the given file, or from stdin when `path`
/// is nil or "-". Shared by all of the CLI's subcommands.
func readInput(path: String?) throws -> String {
    guard let path, path != "-" else {
        let data = FileHandle.standardInput.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
    return try String(contentsOfFile: path, encoding: .utf8)
}
