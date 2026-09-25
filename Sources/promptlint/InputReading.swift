import Foundation

/// Lê o texto a analisar do arquivo indicado, ou de stdin quando `path` é
/// nil ou "-". Compartilhado por todos os subcomandos da CLI.
func readInput(path: String?) throws -> String {
    guard let path, path != "-" else {
        let data = FileHandle.standardInput.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
    return try String(contentsOfFile: path, encoding: .utf8)
}
