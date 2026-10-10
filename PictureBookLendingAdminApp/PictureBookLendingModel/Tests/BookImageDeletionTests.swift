import Foundation
import PictureBookLendingDomain
import XCTest

@testable import PictureBookLendingModel

@MainActor
final class BookImageDeletionTests: XCTestCase {
    func testSharedImageSurvivesUntilLastBookIsDeleted() throws {
        let books = MockBookRepository()
        let images = DeletionImageRepository()
        let first = try books.save(Book(title: "架空の本1", localImageFileName: "shared.jpg"))
        try images.saveImageData(Data([1]), fileName: "shared.jpg")
        let model = BookModel(repository: books, imageStorageRepository: images)
        let second = try books.save(Book(title: "架空の本2", localImageFileName: "shared.jpg"))
        XCTAssertTrue(try model.deleteBook(first.id))
        XCTAssertNotNil(images.loadImageData(fileName: "shared.jpg"))
        // Recreating the model must use persisted references, not the old cache.
        let reopened = BookModel(repository: books, imageStorageRepository: images)
        XCTAssertTrue(try reopened.deleteBook(second.id))
        XCTAssertNil(images.loadImageData(fileName: "shared.jpg"))
        XCTAssertTrue(try books.fetchAll().isEmpty)
    }

    func testResetDeletesBooksSharedPhotosAndOrphans() throws {
        let books = MockBookRepository()
        let images = DeletionImageRepository()
        _ = try books.save(Book(title: "架空の本1", localImageFileName: "shared.jpg"))
        _ = try books.save(Book(title: "架空の本2", localImageFileName: "shared.jpg"))
        try images.saveImageData(Data([1]), fileName: "shared.jpg")
        try images.saveImageData(Data([2]), fileName: "orphan.jpg")
        let model = BookModel(repository: books, imageStorageRepository: images)
        XCTAssertEqual(try model.deleteAllBooks(), 2)
        XCTAssertTrue(try books.fetchAll().isEmpty)
        XCTAssertNil(images.loadImageData(fileName: "shared.jpg"))
        XCTAssertNil(images.loadImageData(fileName: "orphan.jpg"))
    }

    func testResetDeletesOrphanImagesEvenWithNoBooks() throws {
        let images = DeletionImageRepository()
        try images.saveImageData(Data([1]), fileName: "old-photo.jpg")
        let model = BookModel(repository: MockBookRepository(), imageStorageRepository: images)
        XCTAssertEqual(try model.deleteAllBooks(), 0)
        XCTAssertNil(images.loadImageData(fileName: "old-photo.jpg"))
    }

    func testImageFailureReportsPartialDeletionAndResetCanRetry() throws {
        let books = MockBookRepository()
        let images = DeletionImageRepository()
        let book = try books.save(Book(title: "架空の本", localImageFileName: "cover.jpg"))
        try images.saveImageData(Data([1]), fileName: "cover.jpg")
        let model = BookModel(repository: books, imageStorageRepository: images)
        images.failDeletion = true
        XCTAssertThrowsError(try model.deleteBook(book.id)) { error in
            XCTAssertEqual(error as? BookModelError, .imageDeletionFailed)
        }
        XCTAssertTrue(model.books.isEmpty)
        XCTAssertTrue(try books.fetchAll().isEmpty)
        XCTAssertNotNil(images.loadImageData(fileName: "cover.jpg"))
        XCTAssertThrowsError(try model.deleteAllBooks())
        images.failDeletion = false
        XCTAssertEqual(try model.deleteAllBooks(), 0)
        XCTAssertNil(images.loadImageData(fileName: "cover.jpg"))
    }

    func testDatabaseFailurePreservesImage() throws {
        let books = FailingDeleteBookRepository()
        let images = DeletionImageRepository()
        let book = try books.save(Book(title: "架空の本", localImageFileName: "keep.jpg"))
        try images.saveImageData(Data([1]), fileName: "keep.jpg")
        let model = BookModel(repository: books, imageStorageRepository: images)
        XCTAssertThrowsError(try model.deleteBook(book.id))
        XCTAssertNotNil(images.loadImageData(fileName: "keep.jpg"))
        XCTAssertEqual(model.books.count, 1)
    }
}

private final class FailingDeleteBookRepository: MockBookRepository, @unchecked Sendable {
    override func delete(_ id: UUID) throws -> Bool { throw RepositoryError.deleteFailed }
}
private final class DeletionImageRepository: MockImageStorageRepository, @unchecked Sendable {
    var failDeletion = false
    override func deleteImage(fileName: String) throws {
        if failDeletion { throw CocoaError(.fileWriteNoPermission) }
        try super.deleteImage(fileName: fileName)
    }
    override func deleteAllImages() throws {
        if failDeletion { throw CocoaError(.fileWriteNoPermission) }
        try super.deleteAllImages()
    }
}
