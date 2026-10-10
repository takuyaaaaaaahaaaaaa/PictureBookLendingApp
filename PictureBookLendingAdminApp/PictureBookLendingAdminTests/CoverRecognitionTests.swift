import Foundation
import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import Testing
import UIKit

@testable import PictureBookLendingAdmin

@Suite("Cover recognition index")
struct CoverRecognitionTests {
    @Test("候補は順位順に最大5件で、閾値未満で補充しない", arguments: [0, 1, 3, 5, 6, 9])
    func candidateLimit(eligibleCount: Int) {
        let eligible = (0..<eligibleCount).map { index in
            CoverMatch(id: UUID(), similarity: 1 - Float(index) * 0.025)
        }
        let below = [
            CoverMatch(id: UUID(), similarity: 0.699), CoverMatch(id: UUID(), similarity: 0.6),
        ]
        let candidates = CoverSearchPolicy.candidates(from: Array((eligible + below).reversed()))
        #expect(candidates.map(\.id) == Array(eligible.prefix(5)).map(\.id))
        #expect(candidates.allSatisfy { $0.similarity >= 0.70 })
    }

    @Test("閾値ちょうどの候補は採用し、下回る候補は除外する")
    func candidateThreshold() {
        let boundary = CoverMatch(id: UUID(), similarity: 0.70)
        let below = CoverMatch(id: UUID(), similarity: 0.69999)
        #expect(CoverSearchPolicy.candidates(from: [below, boundary]).map(\.id) == [boundary.id])
    }

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
        #expect(
            UIImage(data: inspection.originalModelInput)?.size == CGSize(width: 256, height: 256))
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
        #expect(
            try await engine.search(imageData: data, validBookIDs: [book.id]).first?.id == book.id)
        let inspection = try await engine.inspectRegistration(book)
        #expect(inspection.isRemote)
        #expect(inspection.rectifiedModelInput == nil)
        #expect(try #require(inspection.originalSimilarity) > 0.999)
    }
    @Test("手動の切り抜きは保存・再読込・索引再構築で維持し、画像差し替えで無効になる")
    func manualCropLifecycle() async throws {
        let fileName = "manual-cover-\(UUID().uuidString).jpg"
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let indexURL = folder.appendingPathComponent("index.json")
        defer {
            _ = ImageStorageUtility.deleteImage(at: fileName)
            try? FileManager.default.removeItem(at: folder)
        }
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 400))
        let image = renderer.image { context in
            UIColor.yellow.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 300, height: 400))
            UIColor.blue.setFill()
            context.fill(CGRect(x: 60, y: 80, width: 180, height: 240))
        }
        let data = try #require(image.jpegData(compressionQuality: 0.9))
        try ImageStorageUtility.writeImageData(data, fileName: fileName)
        let book = Book(title: "手動範囲の合成検証", localImageFileName: fileName)
        let engine = CoverRecognitionEngine(indexURL: indexURL)
        #expect(try await engine.indexIfNeeded(book))
        let inspection = try await engine.inspectRegistration(book)
        let rect = CGRect(x: 0.2, y: 0.2, width: 0.6, height: 0.6)
        try await engine.saveManualCrop(
            book, imageData: inspection.sourceImage,
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
        let migrated = try JSONDecoder().decode(
            [UUID: CropStorageFixture].self,
            from: Data(contentsOf: metadataURL))
        #expect(migrated[book.id]?.imageData == nil)
        #expect(try #require(saved.rectifiedSimilarity) > 0.999)
        #expect(await reloaded.indexedCount() == 1)
        let snapshot = try Data(contentsOf: indexURL)
        do {
            try await reloaded.saveManualCrop(
                book, imageData: inspection.sourceImage,
                source: inspection.sourceIdentity,
                rect: CGRect(x: -0.1, y: 0, width: 0.5, height: 0.5))
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

    @Test("確認済みの表紙は新端末・更新日時変更後もバックアップから復元できる")
    func preparationBackupRestoresApprovedPixels() async throws {
        let fileName = "backup-cover-\(UUID().uuidString).jpg"
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer {
            _ = ImageStorageUtility.deleteImage(at: fileName)
            try? FileManager.default.removeItem(at: folder)
        }
        let image = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 400)).image {
            context in
            UIColor.yellow.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 300, height: 400))
            UIColor.blue.setFill()
            context.fill(CGRect(x: 80, y: 80, width: 150, height: 220))
        }
        let pixels = try #require(image.jpegData(compressionQuality: 0.9))
        try ImageStorageUtility.writeImageData(pixels, fileName: fileName)
        let book = Book(title: "架空の復元確認表紙", localImageFileName: fileName)
        let original = CoverRecognitionEngine(indexURL: folder.appendingPathComponent("old.json"))
        try await original.approveRegisteredPhoto(book)
        let before = try await original.inspectRegistration(book)
        let backup = try await original.exportPreparation(
            books: [book], bookImages: [fileName: pixels])
        try ImageStorageUtility.writeImageData(pixels, fileName: fileName)
        try FileManager.default.setAttributes(
            [.modificationDate: Date(timeIntervalSince1970: 12345)],
            ofItemAtPath: ImageStorageUtility.imageURL(for: fileName).path)
        let newURL = folder.appendingPathComponent("new-device.json")
        let restored = CoverRecognitionEngine(indexURL: newURL)
        try await restored.validatePreparation(backup)
        try await restored.restorePreparation(backup, books: [book])
        #expect(await restored.indexedCount() == 0)
        #expect(try await restored.indexIfNeeded(book))
        let after = try await restored.inspectRegistration(book)
        #expect(after.sourceIdentity != before.sourceIdentity)
        #expect(after.manualRect == CGRect(x: 0, y: 0, width: 1, height: 1))
        #expect(after.rectifiedModelInput == before.rectifiedModelInput)
        let reopened = CoverRecognitionEngine(indexURL: newURL)
        #expect(try await reopened.inspectRegistration(book).manualRect == after.manualRect)
        #expect(
            try await reopened.search(imageData: pixels, validBookIDs: [book.id]).first?.id
                == book.id)
        // Invalid preparation must fail before changing persisted data.
        let previous = try Data(contentsOf: newURL.appendingPathExtension("crops.json"))
        do {
            try await reopened.restorePreparation(Data("invalid".utf8), books: [book])
            Issue.record("Reject invalid backup")
        } catch {}
        #expect(try Data(contentsOf: newURL.appendingPathExtension("crops.json")) == previous)
        // Old backups have no manual metadata; never reuse a previous library's crops.
        try await reopened.restorePreparation(nil, books: [book])
        #expect(try await reopened.inspectRegistration(book).manualRect == nil)
    }

    @Test("調整情報の破損時は残る図書の画像を孤立と誤判定して削除しない")
    func unreadablePreparationPreservesPixelsUntilFullReset() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString)
        let indexURL = folder.appendingPathComponent("index.json")
        let copies = indexURL.appendingPathExtension("crop-images")
        try FileManager.default.createDirectory(at: copies, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let metadataURL = indexURL.appendingPathExtension("crops.json")
        let damaged = Data("damaged metadata".utf8)
        try damaged.write(to: metadataURL)
        let pixels = copies.appendingPathComponent("possibly-retained.image")
        try Data([1]).write(to: pixels)
        let engine = CoverRecognitionEngine(indexURL: indexURL)
        do {
            try await engine.removeBooks(notIn: [UUID()])
            Issue.record("Report unreadable metadata")
        } catch CoverRecognitionError.unreadablePreparation {}
        #expect(try Data(contentsOf: metadataURL) == damaged)
        #expect(FileManager.default.fileExists(atPath: pixels.path))
        try await engine.removeBooks(notIn: [])
        #expect(try FileManager.default.contentsOfDirectory(atPath: copies.path).isEmpty)
    }

    @Test("削除後も残る未索引の図書の検索準備を再開する")
    func deletionResumesPreparationForRemainingBooks() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let fileName = "resume-test-\(UUID().uuidString).png"
        defer {
            _ = ImageStorageUtility.deleteImage(at: fileName)
            try? FileManager.default.removeItem(at: folder)
        }
        let pixels = UIGraphicsImageRenderer(size: CGSize(width: 20, height: 20)).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 20, height: 20))
        }
        try ImageStorageUtility.writeImageData(try #require(pixels.pngData()), fileName: fileName)
        let book = Book(title: "残る未索引の架空本", localImageFileName: fileName)
        let engine = CoverRecognitionEngine(indexURL: folder.appendingPathComponent("index.json"))
        let service = await CoverRecognitionService(engine: engine)
        try await service.removeDeletedBooks(books: [book], isComplete: true)
        // Bound the wait: a missing follow-up task must fail rather than hang CI.
        for _ in 0..<2_000 {
            if await service.preparedCount == 1 { break }
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(await service.preparedCount == 1)
        #expect(await engine.indexedCount() == 1)
        #expect(await service.pendingCount == 0)
    }

    @Test("調整情報を除いたバックアップの復元で破損状態から回復できる")
    func restoreWithoutPreparationRecoversDamagedMetadata() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let indexURL = folder.appendingPathComponent("index.json")
        try Data("damaged".utf8).write(to: indexURL.appendingPathExtension("crops.json"))
        let book = Book(title: "架空の復元本", thumbnail: "https://example.invalid/cover.jpg")
        let engine = CoverRecognitionEngine(indexURL: indexURL)
        do {
            _ = try await engine.exportPreparation(books: [book], bookImages: [:])
            Issue.record("Do not silently omit crops")
        } catch CoverRecognitionError.unreadablePreparation {}
        // The settings screen requires confirmation before exporting this nil archive.
        try await engine.restorePreparation(nil, books: [book])
        try await engine.removeBooks(notIn: [book.id])
        let backup = try await engine.exportPreparation(books: [book], bookImages: [:])
        try await engine.validatePreparation(backup)
    }

    @Test("削除失敗は報告し、再起動後に孤立した検索用コピーを削除できる")
    func derivativeDeletionFailureAndRetry() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let indexURL = folder.appendingPathComponent("index.json")
        let fileName = "deletion-test-\(UUID().uuidString).jpg"
        defer {
            _ = ImageStorageUtility.deleteImage(at: fileName)
            try? FileManager.default.removeItem(at: folder)
        }
        let image = UIGraphicsImageRenderer(size: CGSize(width: 20, height: 20)).image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 20, height: 20))
        }
        try ImageStorageUtility.writeImageData(try #require(image.pngData()), fileName: fileName)
        let removed = Book(title: "削除する架空本", localImageFileName: fileName)
        let retained = Book(title: "残す架空本", localImageFileName: fileName)
        let engine = CoverRecognitionEngine(
            indexURL: indexURL,
            deleteFile: { _ in
                throw CocoaError(.fileWriteNoPermission)
            })
        try await engine.approveRegisteredPhoto(removed)
        try await engine.approveRegisteredPhoto(retained)
        let copies = indexURL.appendingPathExtension("crop-images")
        try Data([1]).write(to: copies.appendingPathComponent("orphan.image"))
        do {
            try await engine.removeBooks(notIn: [retained.id])
            Issue.record("Report file deletion failure")
        } catch {}
        #expect(await engine.indexedCount() == 1)
        let reopened = CoverRecognitionEngine(indexURL: indexURL)
        #expect(try await reopened.inspectRegistration(removed).manualRect == nil)
        #expect(try await reopened.inspectRegistration(retained).manualRect != nil)
        try await reopened.removeBooks(notIn: [retained.id])
        #expect(try FileManager.default.contentsOfDirectory(atPath: copies.path).count == 1)
        try await reopened.removeBooks(notIn: [])
        #expect(await reopened.indexedCount() == 0)
        #expect(try FileManager.default.contentsOfDirectory(atPath: copies.path).isEmpty)
        let final = CoverRecognitionEngine(indexURL: indexURL)
        #expect(await final.indexedCount() == 0)
        #expect(try await final.inspectRegistration(retained).manualRect == nil)
    }

    @Test("復元・削除前から取得中の書影を索引へ書き戻さない", .serialized, arguments: [false, true])
    func suspendedDownloadCannotResurrectRestoredIndex(deleteOnly: Bool) async throws {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 20, height: 20)).image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 20, height: 20))
        }
        let pixels = try #require(image.pngData())
        let events = AsyncStream<BlockingCoverURLProtocol> { continuation in
            BlockingCoverURLProtocol.onStart = { continuation.yield($0) }
        }
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [BlockingCoverURLProtocol.self]
        let session = URLSession(configuration: config)
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer {
            session.invalidateAndCancel()
            BlockingCoverURLProtocol.onStart = nil
            try? FileManager.default.removeItem(at: folder)
        }
        let engine = CoverRecognitionEngine(
            indexURL: folder.appendingPathComponent("index.json"), session: session)
        let book = Book(title: "架空の取得中表紙", thumbnail: "https://example.invalid/delayed.jpg")
        let task = Task { try await engine.indexIfNeeded(book) }
        var iterator = events.makeAsyncIterator()
        let request = try #require(await iterator.next())
        if deleteOnly {
            try await engine.removeBooks(notIn: [])
        } else {
            try await engine.restorePreparation(nil, books: [])
        }
        request.complete(pixels)
        #expect(try await task.value == false)
        #expect(await engine.indexedCount() == 0)
    }

    @Test("自動候補は連続一致で表示し、不一致や候補なしで確認をやり直す")
    func liveConfirmation() {
        let first = UUID()
        let second = UUID()
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
        let response = HTTPURLResponse(
            url: request.url!, statusCode: 200, httpVersion: nil,
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

private final class BlockingCoverURLProtocol: URLProtocol {
    static var onStart: ((BlockingCoverURLProtocol) -> Void)?
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() { Self.onStart?(self) }
    override func stopLoading() {}
    func complete(_ data: Data) {
        guard let url = request.url,
            let response = HTTPURLResponse(
                url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
        else { return }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }
}
