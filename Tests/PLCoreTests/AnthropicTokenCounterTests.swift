import XCTest
@testable import PLCore

private final class StubURLProtocol: URLProtocol {
    static var responseData: Data = Data()
    static var statusCode: Int = 200
    static var lastRequest: URLRequest?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.lastRequest = request
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: Self.statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.responseData)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

final class AnthropicTokenCounterTests: XCTestCase {
    private func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    func testParsesInputTokensFromResponse() async throws {
        StubURLProtocol.statusCode = 200
        StubURLProtocol.responseData = try JSONSerialization.data(withJSONObject: ["input_tokens": 42])

        let counter = AnthropicTokenCounter(model: "claude-sonnet-5", apiKey: "test-key", session: makeSession())
        let count = try await counter.count("qualquer texto")

        XCTAssertEqual(count, 42)
        XCTAssertEqual(StubURLProtocol.lastRequest?.value(forHTTPHeaderField: "x-api-key"), "test-key")
        XCTAssertEqual(StubURLProtocol.lastRequest?.value(forHTTPHeaderField: "anthropic-version"), "2023-06-01")
    }

    func testThrowsOnNonSuccessStatusCode() async {
        StubURLProtocol.statusCode = 401
        StubURLProtocol.responseData = Data("unauthorized".utf8)

        let counter = AnthropicTokenCounter(model: "claude-sonnet-5", apiKey: "test-key", session: makeSession())

        do {
            _ = try await counter.count("qualquer texto")
            XCTFail("Deveria lançar erro para status != 2xx")
        } catch let error as AnthropicTokenCounterError {
            guard case .requestFailed(let statusCode, _) = error else {
                return XCTFail("Erro inesperado: \(error)")
            }
            XCTAssertEqual(statusCode, 401)
        } catch {
            XCTFail("Tipo de erro inesperado: \(error)")
        }
    }
}
