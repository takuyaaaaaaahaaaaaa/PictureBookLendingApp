import XCTest

@testable import PictureBookLendingDomain

final class BackupSnapshotTests: XCTestCase {
    
    func testEncodeDecodeRoundTrip() throws {
        let classGroup = ClassGroup(name: "ひよこ組", ageGroup: .age(3), year: 2026)
        let user = User(name: "たろう", classGroupId: classGroup.id, userType: .child)
        let book = Book(title: "はらぺこあおむし", author: "エリック・カール", managementNumber: "あ001")
        let loan = Loan(
            bookId: book.id, user: user, loanDate: Date(timeIntervalSince1970: 0),
            dueDate: Date(timeIntervalSince1970: 86400))
        
        let snapshot = BackupSnapshot(
            createdAt: Date(timeIntervalSince1970: 0),
            classGroups: [classGroup],
            users: [user],
            books: [book],
            loans: [loan],
            loanSettings: .default,
            bookImages: ["a.jpg": Data([0x01, 0x02, 0x03])]
        )
        
        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(BackupSnapshot.self, from: data)
        
        XCTAssertEqual(decoded.schemaVersion, BackupSnapshot.currentSchemaVersion)
        XCTAssertEqual(decoded.classGroups, [classGroup])
        XCTAssertEqual(decoded.users, [user])
        XCTAssertEqual(decoded.books, [book])
        XCTAssertEqual(decoded.loans.first?.id, loan.id)
        XCTAssertEqual(decoded.loanSettings, LoanSettings.default)
        XCTAssertEqual(decoded.bookImages["a.jpg"], Data([0x01, 0x02, 0x03]))
    }
    
    func testDefaultSchemaVersion() {
        let snapshot = BackupSnapshot(
            createdAt: Date(),
            classGroups: [],
            users: [],
            books: [],
            loans: [],
            loanSettings: .default,
            bookImages: [:]
        )
        
        XCTAssertEqual(snapshot.schemaVersion, 1)
    }
}
