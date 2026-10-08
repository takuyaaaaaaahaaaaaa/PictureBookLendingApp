import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import Foundation
import Testing
import UIKit
@testable import PictureBookLendingAdmin
@Suite("Cover recognition index")
struct CoverRecognitionTests {
    @Test("画像登録、保存・再読込、候補検索、削除")
    func indexLifecycle() async throws {
        let fileName = "cover-test-\(UUID().uuidString).jpg"
        let indexURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("cover-index-\(UUID().uuidString).json")
        defer {
            _ = ImageStorageUtility.deleteImage(at: fileName)
            try? FileManager.default.removeItem(at: indexURL)
        }
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 256, height: 256))
        let image = renderer.image { context in
            UIColor.systemYellow.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 256, height: 256))
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 35, y: 35, width: 170, height: 170))
        }
        let data = try #require(image.jpegData(compressionQuality: 0.9))
        try ImageStorageUtility.writeImageData(data, fileName: fileName)
        let book = Book(title: "検証用の合成表紙", localImageFileName: fileName)
        let engine = CoverRecognitionEngine(indexURL: indexURL)
        #expect(try await engine.indexIfNeeded(book))
        #expect(await engine.indexedCount() == 1)
        let matches = try await engine.search(imageData: data, validBookIDs: [book.id])
        #expect(matches.first?.id == book.id)
        let reloaded = CoverRecognitionEngine(indexURL: indexURL)
        #expect(await reloaded.indexedCount() == 1)
        #expect(
            try await reloaded.search(imageData: data, validBookIDs: [book.id]).first?.id == book.id
        )
        try await reloaded.removeBooks(notIn: [])
        #expect(await reloaded.indexedCount() == 0)
    }
    @Test("既存の外部書影を再取得して索引へ登録")
    func remoteCoverBackfill() async throws {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 256, height: 256))
        let image = renderer.image { context in
            UIColor.systemGreen.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 256, height: 256))
            UIColor.systemRed.setFill()
            context.fill(CGRect(x: 40, y: 40, width: 80, height: 80))
        }
        let data = try #require(image.jpegData(compressionQuality: 0.9))
        MockCoverURLProtocol.imageData = data
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockCoverURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let indexURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("remote-cover-index-\(UUID().uuidString).json")
        defer {
            session.invalidateAndCancel()
            try? FileManager.default.removeItem(at: indexURL)
        }
        let book = Book(title: "公開書影の検証", thumbnail: "https://example.invalid/cover.jpg")
        let engine = CoverRecognitionEngine(indexURL: indexURL, session: session)
        #expect(try await engine.indexIfNeeded(book))
        #expect(try await engine.search(imageData: data, validBookIDs: [book.id]).first?.id == book.id)
    }
}
private final class MockCoverURLProtocol: URLProtocol {
    static var imageData = Data()
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil,
                                       headerFields: ["Content-Type": "image/jpeg"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.imageData)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}
