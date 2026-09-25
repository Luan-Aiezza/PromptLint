import Foundation

public enum AnthropicTokenCounterError: Error, CustomStringConvertible {
    case missingAPIKey
    case invalidResponse
    case requestFailed(statusCode: Int, body: String)

    public var description: String {
        switch self {
        case .missingAPIKey:
            return "ANTHROPIC_API_KEY is not set. Export the environment variable or pass --api-key."
        case .invalidResponse:
            return "Unexpected response from the count_tokens endpoint."
        case .requestFailed(let statusCode, let body):
            return "count_tokens failed (HTTP \(statusCode)): \(body)"
        }
    }
}

/// Exact counting via `POST /v1/messages/count_tokens`. Do not use tiktoken
/// or any other provider's estimate — Anthropic's tokenizer isn't public and
/// diverges from other BPEs, especially on code and non-English text.
public struct AnthropicTokenCounter: TokenCounter {
    private static let endpoint = URL(string: "https://api.anthropic.com/v1/messages/count_tokens")!
    private static let apiVersion = "2023-06-01"

    private let model: String
    private let apiKey: String
    private let session: URLSession

    public init(model: String, apiKey: String, session: URLSession = .shared) {
        self.model = model
        self.apiKey = apiKey
        self.session = session
    }

    public func count(_ text: String) async throws -> Int {
        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(Self.apiVersion, forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "model": model,
            "messages": [["role": "user", "content": text]],
        ])

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AnthropicTokenCounterError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw AnthropicTokenCounterError.requestFailed(
                statusCode: http.statusCode,
                body: String(data: data, encoding: .utf8) ?? ""
            )
        }

        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let inputTokens = object["input_tokens"] as? Int else {
            throw AnthropicTokenCounterError.invalidResponse
        }
        return inputTokens
    }
}
