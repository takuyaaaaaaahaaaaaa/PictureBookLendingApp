import Foundation

/// テスト用のURLProtocolモック
///
/// URLSessionのリクエストをインターセプトし、あらかじめ設定した
/// レスポンスを返すことで、実際のネットワーク通信なしにゲートウェイの
/// パース・マッピングロジックを検証できるようにします。
final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    
    /// リクエストに対して返すレスポンスを決定するハンドラ
    /// - Returns: (HTTPステータスコード, ボディデータ)
    nonisolated(unsafe) static var responseHandler:
        (@Sendable (URLRequest) throws -> (statusCode: Int, data: Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }
    
    override func startLoading() {
        guard let handler = Self.responseHandler else {
            client?.urlProtocol(
                self, didFailWithError: URLError(.badServerResponse))
            return
        }
        
        do {
            let (statusCode, data) = try handler(request)
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    override func stopLoading() {}
    
    /// モックを設定したURLSessionを生成する
    /// - Parameter handler: リクエストに対するレスポンスを返すハンドラ
    /// - Returns: モック済みのURLSession
    static func makeSession(
        handler: @escaping @Sendable (URLRequest) throws -> (statusCode: Int, data: Data)
    ) -> URLSession {
        responseHandler = handler
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}
