import Foundation
import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import Testing
import UIKit

@testable import PictureBookLendingAdmin

@Suite("Cover preparation readiness", .serialized)
@MainActor
struct CoverPreparationTests {
    @Test("未読込の蔵書を準備済み0件と扱わず、読込後の空蔵書は確定する")
    func unknownAndEmptyCatalog() async throws {
        let folder = try temporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let service = CoverRecognitionService(
            engine: CoverRecognitionEngine(indexURL: folder.appendingPathComponent("index.json")))
        #expect(!service.hasCheckedPreparation)
        await service.prepare(books: [], isComplete: false)
        #expect(!service.hasCheckedPreparation)
        await service.prepare(books: [], isComplete: true)
        #expect(service.hasCheckedPreparation)
        #expect(service.preparedBookIDs.isEmpty)
        #expect(service.pendingCount == 0)
        #expect(!service.isPreparing)
    }

    @Test("画像のない本は再試行後も未処理となり、架空の準備完了を表示しない")
    func missingImagesRemainPending() async throws {
        let folder = try temporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let service = CoverRecognitionService(
            engine: CoverRecognitionEngine(indexURL: folder.appendingPathComponent("index.json")))
        let books = [Book(title: "表紙なしの架空本")]
        await service.prepare(books: books, isComplete: true)
        await service.prepare(books: books, isComplete: true)
        #expect(service.hasCheckedPreparation)
        #expect(service.preparedCount == 0)
        #expect(service.pendingCount == 1)
        #expect(!service.isPreparing)
    }

    @Test("未処理だった本の写真確認後は、再準備を待たず未処理件数が減る")
    func approvalUpdatesPendingCount() async throws {
        let folder = try temporaryFolder()
        let fileName = "pending-\(UUID().uuidString).png"
        defer {
            _ = ImageStorageUtility.deleteImage(at: fileName)
            try? FileManager.default.removeItem(at: folder)
        }
        let service = CoverRecognitionService(
            engine: CoverRecognitionEngine(indexURL: folder.appendingPathComponent("index.json")))
        var book = Book(title: "写真を追加する架空本")
        await service.prepare(books: [book], isComplete: true)
        #expect(service.pendingCount == 1)
        let pixels = UIGraphicsImageRenderer(size: CGSize(width: 32, height: 48)).image { context in
            UIColor.green.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 32, height: 48))
        }
        try ImageStorageUtility.writeImageData(try #require(pixels.pngData()), fileName: fileName)
        book.localImageFileName = fileName
        try await service.approveRegisteredPhoto(book)
        #expect(service.pendingCount == 0)
        #expect(service.hasPreparedBook(in: [book], isComplete: true))
        #expect(!service.hasPreparedBook(in: [book], isComplete: false))
        #expect(!service.hasPreparedBook(in: [], isComplete: true))
    }

    @Test("再起動後の保存済み表紙は、先頭の遅いダウンロードと重複準備要求を待たず検索可能")
    func persistedReadinessDuringPreparation() async throws {
        let folder = try temporaryFolder()
        let fileName = "readiness-\(UUID().uuidString).png"
        defer {
            _ = ImageStorageUtility.deleteImage(at: fileName)
            try? FileManager.default.removeItem(at: folder)
        }
        let image = UIGraphicsImageRenderer(size: CGSize(width: 32, height: 48)).image { context in
            UIColor.orange.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 32, height: 48))
        }
        let pixels = try #require(image.pngData())
        try ImageStorageUtility.writeImageData(pixels, fileName: fileName)
        let readyBook = Book(title: "準備済みの架空本", localImageFileName: fileName)
        let indexURL = folder.appendingPathComponent("index.json")
        let writer = CoverRecognitionEngine(indexURL: indexURL)
        #expect(try await writer.indexIfNeeded(readyBook))
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [PreparationBlockingURLProtocol.self]
        let session = URLSession(configuration: config)
        defer {
            session.invalidateAndCancel()
            PreparationBlockingURLProtocol.onStart = nil
        }
        let events = AsyncStream<PreparationBlockingURLProtocol> { continuation in
            PreparationBlockingURLProtocol.onStart = { continuation.yield($0) }
        }
        let engine = CoverRecognitionEngine(indexURL: indexURL, session: session)
        let service = CoverRecognitionService(engine: engine)
        let remote = Book(title: "遅い外部表紙の架空本", thumbnail: "https://example.invalid/preparation.jpg")
        let books = [remote, readyBook]
        let task = Task { await service.prepare(books: books, isComplete: true) }
        var iterator = events.makeAsyncIterator()
        let request = try #require(await iterator.next())
        #expect(service.isPreparing)
        #expect(service.hasCheckedPreparation)
        #expect(service.preparedBookIDs == [readyBook.id])
        #expect(service.pendingCount == 1)
        // A second request must not clear the existing availability or start a second download.
        await service.prepare(books: [readyBook], isComplete: true)
        #expect(service.preparedBookIDs.contains(readyBook.id))
        request.fail()
        await task.value
        for _ in 0..<200 {
            if service.pendingCount == 0 && !service.isPreparing { break }
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(service.preparedBookIDs == [readyBook.id])
        #expect(service.pendingCount == 0)
        #expect(!service.isPreparing)
        #expect(await engine.preparedBookIDs(in: [remote]).isEmpty)
    }

    @Test("削除・復元エラーでも実際の索引状態を反映し、準備済みの本を検索できる")
    func failuresRefreshActualReadiness() async throws {
        let folder = try temporaryFolder()
        let fileName = "readiness-error-\(UUID().uuidString).png"
        defer {
            _ = ImageStorageUtility.deleteImage(at: fileName)
            try? FileManager.default.removeItem(at: folder)
        }
        let pixels = UIGraphicsImageRenderer(size: CGSize(width: 32, height: 48)).image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 32, height: 48))
        }
        try ImageStorageUtility.writeImageData(try #require(pixels.pngData()), fileName: fileName)
        let book = Book(title: "エラー後も残る架空本", localImageFileName: fileName)
        let indexURL = folder.appendingPathComponent("index.json")
        let writer = CoverRecognitionEngine(indexURL: indexURL)
        #expect(try await writer.indexIfNeeded(book))
        let copies = indexURL.appendingPathExtension("crop-images")
        try FileManager.default.createDirectory(at: copies, withIntermediateDirectories: true)
        try Data([1]).write(to: copies.appendingPathComponent("orphan.image"))
        let engine = CoverRecognitionEngine(
            indexURL: indexURL, deleteFile: { _ in throw CocoaError(.fileWriteNoPermission) })
        let service = CoverRecognitionService(engine: engine)
        await service.prepare(books: [book], isComplete: true)
        #expect(service.hasCheckedPreparation)
        #expect(service.preparationError != nil)
        #expect(service.hasPreparedBook(in: [book], isComplete: true))
        do {
            try await service.restorePreparation(
                Data("invalid".utf8), books: [book], isComplete: true)
            Issue.record("Invalid backup must fail")
        } catch {}
        #expect(service.hasCheckedPreparation)
        #expect(service.preparedCount == 1)
        #expect(service.hasPreparedBook(in: [book], isComplete: true))
        do {
            try await service.removeDeletedBooks(books: [], isComplete: true)
            Issue.record("Cleanup failure must be reported")
        } catch {}
        #expect(service.hasCheckedPreparation)
        #expect(service.preparedCount == 0)
        #expect(service.pendingCount == 0)
        #expect(!service.isPreparing)
    }

    private func temporaryFolder() throws -> URL {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }
}

private final class PreparationBlockingURLProtocol: URLProtocol {
    nonisolated(unsafe) static var onStart: ((PreparationBlockingURLProtocol) -> Void)?
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() { Self.onStart?(self) }
    override func stopLoading() {}
    func fail() { client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet)) }
}
