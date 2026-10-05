import Foundation
import Kingfisher
import XCTest

@testable import PictureBookLendingUI

@MainActor
final class ExternalBookCoverCacheTests: XCTestCase {
    private let png = Data(
        base64Encoded:
            "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP4z8DwHwAFAAH/iZk9HQAAAABJRU5ErkJggg=="
    )!

    func testRemoteCoverUsesFixedExpiryAndNeverFallsBackToExpiredImage() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("cover-cache-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let cache = try ImageCache(name: "test-\(UUID().uuidString)", cacheDirectoryURL: directory)
        let url = URL(string: "https://covers.invalid/book.png")!
        let productionSettings = ExternalBookCoverCache.image(for: url, cache: cache).options
        guard case .days(let days)? = productionSettings.diskCacheExpiration else {
            return XCTFail("外部表紙の既定期限は30日")
        }
        XCTAssertEqual(days, 30)
        let configured = ExternalBookCoverCache.image(
            for: url, cache: cache, expiration: .seconds(60))
        let settings = configured.options
        XCTAssertTrue(settings.targetCache === cache)
        guard case .expired = settings.memoryCacheExpiration else {
            return XCTFail("外部表紙は期限を超えたメモリ画像を再利用しない")
        }
        guard case .none = settings.diskCacheAccessExtendingExpiration else {
            return XCTFail("ディスク期限を参照時に延長しない")
        }

        let state = CoverRequestState(png: png)
        CoverURLProtocol.state = state
        defer { CoverURLProtocol.state = nil }
        let session = URLSessionConfiguration.ephemeral
        session.protocolClasses = [CoverURLProtocol.self]
        let downloader = ImageDownloader(name: "test-\(UUID().uuidString)")
        downloader.sessionConfiguration = session
        let options: KingfisherOptionsInfo = [
            .targetCache(cache),
            .downloader(downloader),
            .memoryCacheExpiration(settings.memoryCacheExpiration!),
            .diskCacheExpiration(settings.diskCacheExpiration!),
            .diskCacheAccessExtendingExpiration(settings.diskCacheAccessExtendingExpiration),
            .waitForCache,
        ]

        let first = try await KingfisherManager.shared.retrieveImage(with: url, options: options)
        XCTAssertFalse(first.cacheType.cached)
        XCTAssertEqual(state.requests, 1)

        let file = cache.diskStorage.cacheFileURL(forKey: url.absoluteString)
        let firstExpiry = try XCTUnwrap(
            FileManager.default.attributesOfItem(atPath: file.path)[.modificationDate] as? Date)
        let second = try await KingfisherManager.shared.retrieveImage(with: url, options: options)
        XCTAssertTrue(second.cacheType.cached)
        XCTAssertEqual(state.requests, 1)
        let secondExpiry = try XCTUnwrap(
            FileManager.default.attributesOfItem(atPath: file.path)[.modificationDate] as? Date)
        XCTAssertEqual(secondExpiry, firstExpiry, "キャッシュヒットで期限が延長されない")

        try FileManager.default.setAttributes(
            [.modificationDate: Date(timeIntervalSince1970: 1)], ofItemAtPath: file.path)
        let refreshed = try await KingfisherManager.shared.retrieveImage(
            with: url, options: options)
        XCTAssertFalse(refreshed.cacheType.cached)
        XCTAssertEqual(state.requests, 2, "期限後は画像だけ再取得する")

        try FileManager.default.setAttributes(
            [.modificationDate: Date(timeIntervalSince1970: 1)], ofItemAtPath: file.path)
        state.shouldFail = true
        do {
            _ = try await KingfisherManager.shared.retrieveImage(with: url, options: options)
            XCTFail("オフライン時は期限切れ画像を返さない")
        } catch {
            XCTAssertEqual(state.requests, 3)
        }
    }

    func testLocalCameraFileDoesNotReceiveExternalCachePolicy() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("camera-cover-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("camera.png")
        try png.write(to: file)
        let cache = try ImageCache(name: "test-\(UUID().uuidString)", cacheDirectoryURL: directory)

        let local = ExternalBookCoverCache.image(for: file, cache: cache, expiration: .seconds(1))
        XCTAssertNil(local.options.targetCache)
        XCTAssertNil(local.options.diskCacheExpiration)
        XCTAssertEqual(try Data(contentsOf: file), png)
    }
}

private final class CoverRequestState: @unchecked Sendable {
    private let lock = NSLock()
    let png: Data
    private var count = 0
    private var fail = false

    init(png: Data) { self.png = png }

    var requests: Int { lock.withLock { count } }
    var shouldFail: Bool {
        get { lock.withLock { fail } }
        set { lock.withLock { fail = newValue } }
    }
    func nextRequestFails() -> Bool {
        lock.withLock {
            count += 1
            return fail
        }
    }
}

private final class CoverURLProtocol: URLProtocol {
    nonisolated(unsafe) static var state: CoverRequestState?

    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.host == "covers.invalid"
    }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        guard let state = Self.state, let url = request.url else { return }
        if state.nextRequestFails() {
            client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
            return
        }
        let response = HTTPURLResponse(
            url: url, statusCode: 200, httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "image/png", "Content-Length": "\(state.png.count)"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: state.png)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}
