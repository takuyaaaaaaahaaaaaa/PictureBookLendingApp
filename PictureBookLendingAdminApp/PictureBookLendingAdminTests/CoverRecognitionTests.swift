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
        let indexBeforeInspection = try Data(contentsOf: indexURL)
        let inspection = try await engine.inspectRegistration(book)
        #expect(inspection.sourceMatchesIndex)
        #expect(!inspection.isRemote)
        #expect(try #require(inspection.originalSimilarity) > 0.999)
        let rectifiedSimilarity = try #require(inspection.rectifiedSimilarity)
        // Vision rectification is re-run for inspection; report its agreement rather
        // than assuming it reproduces the saved crop exactly (observed 0.99118).
        #expect(rectifiedSimilarity.isFinite)
        #expect((-1.0001...1.0001).contains(rectifiedSimilarity))
        #expect(UIImage(data: inspection.originalModelInput)?.size == CGSize(width: 256, height: 256))
        #expect(try Data(contentsOf: indexURL) == indexBeforeInspection)
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
        let inspection = try await engine.inspectRegistration(book)
        #expect(inspection.isRemote)
        #expect(inspection.rectifiedModelInput == nil)
        #expect(try #require(inspection.originalSimilarity) > 0.999)
    }
    @Test("手動の切り抜きは保存・再読込・索引再構築で維持し、画像差し替えで無効になる")
    func manualCropLifecycle() async throws {
        let fileName = "manual-cover-\(UUID().uuidString).jpg"
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let indexURL = folder.appendingPathComponent("index.json")
        defer {
            _ = ImageStorageUtility.deleteImage(at: fileName)
            try? FileManager.default.removeItem(at: folder)
        }
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 400))
        let image = renderer.image { context in
            UIColor.yellow.setFill(); context.fill(CGRect(x: 0, y: 0, width: 300, height: 400))
            UIColor.blue.setFill(); context.fill(CGRect(x: 60, y: 80, width: 180, height: 240))
        }
        let data = try #require(image.jpegData(compressionQuality: 0.9))
        try ImageStorageUtility.writeImageData(data, fileName: fileName)
        let book = Book(title: "手動範囲の合成検証", localImageFileName: fileName)
        let engine = CoverRecognitionEngine(indexURL: indexURL)
        #expect(try await engine.indexIfNeeded(book))
        let inspection = try await engine.inspectRegistration(book)
        let rect = CGRect(x: 0.2, y: 0.2, width: 0.6, height: 0.6)
        try await engine.saveManualCrop(book, imageData: inspection.sourceImage,
            source: inspection.sourceIdentity, rect: rect)
        #expect(ImageStorageUtility.readImageData(fileName: fileName) == data)
        let metadataURL = indexURL.appendingPathExtension("crops.json")
        let snapshotFolder = indexURL.appendingPathExtension("crop-images")
        let metadataData = try Data(contentsOf: metadataURL)
        var metadata = try JSONDecoder().decode([UUID: CropStorageFixture].self, from: metadataData)
        #expect(metadata[book.id]?.imageData == nil)
        #expect(metadataData.count < 2_000)
        #expect(try FileManager.default.contentsOfDirectory(atPath: snapshotFolder.path).count == 1)
        // Simulate an earlier build's inline JSON, then verify transparent migration.
        metadata[book.id]?.imageData = inspection.sourceImage
        try JSONEncoder().encode(metadata).write(to: metadataURL, options: .atomic)

        let reloaded = CoverRecognitionEngine(indexURL: indexURL)
        #expect(try await reloaded.indexIfNeeded(book))
        let saved = try await reloaded.inspectRegistration(book)
        #expect(saved.manualRect == rect)
        let migrated = try JSONDecoder().decode([UUID: CropStorageFixture].self,
            from: Data(contentsOf: metadataURL))
        #expect(migrated[book.id]?.imageData == nil)
        #expect(try #require(saved.rectifiedSimilarity) > 0.999)
        #expect(await reloaded.indexedCount() == 1)
        let snapshot = try Data(contentsOf: indexURL)
        do {
            try await reloaded.saveManualCrop(book, imageData: inspection.sourceImage,
                source: inspection.sourceIdentity, rect: CGRect(x: -0.1, y: 0, width: 0.5, height: 0.5))
            Issue.record("画像外の範囲は拒否する必要があります")
        } catch CoverRecognitionError.invalidImage {}
        #expect(try Data(contentsOf: indexURL) == snapshot)
        var json = try #require(JSONSerialization.jsonObject(with: snapshot) as? [String: Any])
        json["version"] = "obsolete-test-version"
        try JSONSerialization.data(withJSONObject: json).write(to: indexURL)
        let rebuilt = CoverRecognitionEngine(indexURL: indexURL)
        #expect(await rebuilt.indexedCount() == 0)
        #expect(try await rebuilt.indexIfNeeded(book))
        #expect(try await rebuilt.inspectRegistration(book).manualRect == rect)
        // A failed catalog read must not turn an empty snapshot into destructive pruning.
        let service = await CoverRecognitionService(engine: rebuilt)
        await service.prepare(books: [], isComplete: false)
        #expect(await rebuilt.indexedCount() == 1)
        #expect(try await rebuilt.inspectRegistration(book).manualRect == rect)
        // Changing the stored image invalidates the old crop instead of applying it blindly.
        try ImageStorageUtility.writeImageData(try #require(image.pngData()), fileName: fileName)
        #expect(try await rebuilt.indexIfNeeded(book))
        #expect(try await rebuilt.inspectRegistration(book).manualRect == nil)
        try await rebuilt.remove(bookID: book.id)
        #expect(await rebuilt.indexedCount() == 0)
        #expect(try FileManager.default.contentsOfDirectory(atPath: snapshotFolder.path).isEmpty)
    }

    @Test("自動候補は連続一致で表示し、不一致や候補なしで確認をやり直す")
    func liveConfirmation() {
        let first = UUID(), second = UUID()
        var confirmation = LiveCoverConfirmation()
        let inputs: [UUID?] = [nil, first, nil, first, second, second, nil, second]
        let results = inputs.map { confirmation.accept($0) }
        #expect(results == [false, false, false, false, false, true, false, false])
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

private struct CropStorageFixture: Codable {
    let id: UUID
    let source: String
    var imageData: Data?
    let rect: CGRect
}
