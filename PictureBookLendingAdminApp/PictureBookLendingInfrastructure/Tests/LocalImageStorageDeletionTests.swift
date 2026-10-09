import Foundation
import XCTest
@testable import PictureBookLendingInfrastructure

final class LocalImageStorageDeletionTests: XCTestCase {
    func testDeletionAndResetPersistAndStayWithinImageDirectory() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let folder = root.appendingPathComponent("BookImages")
        defer { try? FileManager.default.removeItem(at: root) }
        let storage = LocalImageStorageRepository(directoryURL: folder)
        try storage.saveImageData(Data([1]), fileName: "one.jpg")
        try storage.saveImageData(Data([2]), fileName: "orphan.jpg")
        let outside = root.appendingPathComponent("keep.txt")
        try Data([3]).write(to: outside)
        XCTAssertThrowsError(try storage.deleteImage(fileName: "../keep.txt"))
        try storage.deleteImage(fileName: "one.jpg")
        try storage.deleteImage(fileName: "one.jpg") // Missing is already deleted.
        let reopened = LocalImageStorageRepository(directoryURL: folder)
        XCTAssertNil(reopened.loadImageData(fileName: "one.jpg"))
        XCTAssertNotNil(reopened.loadImageData(fileName: "orphan.jpg"))
        try reopened.deleteAllImages()
        XCTAssertFalse(FileManager.default.fileExists(atPath: folder.path))
        XCTAssertEqual(try Data(contentsOf: outside), Data([3]))
        try reopened.deleteAllImages()
    }
}
