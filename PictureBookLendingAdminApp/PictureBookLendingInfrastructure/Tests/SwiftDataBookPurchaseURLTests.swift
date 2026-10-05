import Foundation
import PictureBookLendingDomain
import SwiftData
import Testing

@testable import PictureBookLendingInfrastructure

@MainActor
struct SwiftDataBookPurchaseURLTests {
    @Test func currentMigrationPlanCreatesStore() throws {
        let schema = Schema([
            SwiftDataBook.self, SwiftDataUser.self, SwiftDataLoan.self, SwiftDataClassGroup.self,
        ])
        let storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("purchase-url-new-store-\(UUID().uuidString).sqlite")
        let container = try ModelContainer(
            for: schema,
            migrationPlan: PictureBookLendingMigrationPlan.self,
            configurations: [ModelConfiguration(schema: schema, url: storeURL)])
        let repository = SwiftDataBookRepository(modelContext: container.mainContext)
        let book = Book(title: "新しい絵本", rakutenItemURL: "https://books.rakuten.co.jp/rb/123/")
        _ = try repository.save(book)
        #expect(try repository.findById(book.id)?.rakutenItemURL == book.rakutenItemURL)
    }

    @Test func purchaseURLSurvivesSaveAndUpdate() throws {
        let container = SwiftDataRepositoryFactory.makeTestModelContainer()
        let repository = SwiftDataBookRepository(modelContext: container.mainContext)
        var book = Book(title: "絵本", rakutenItemURL: "https://books.rakuten.co.jp/rb/123/")
        _ = try repository.save(book)
        #expect(try repository.findById(book.id)?.rakutenItemURL == book.rakutenItemURL)

        book.managementNumber = "あ001"
        _ = try repository.update(book)
        let restored = try repository.findById(book.id)
        #expect(restored?.rakutenItemURL == book.rakutenItemURL)
        #expect(restored?.managementNumber == "あ001")
    }
}
