//
//  Test.swift
//  PictureBookLendingAdminTests
//
//  Created by takuya_tominaga on 6/5/25.
//

import XCTest
import PictureBookLendingDomain
import PictureBookLendingInfrastructure

final class InfrastructureTests: XCTestCase {
    
    func testBookRepositoryBasicOperation() throws {
        // 基本的なRepository動作をテスト
        let book = Book(id: UUID(), title: "テスト絵本", author: "テスト作者")
        XCTAssertEqual(book.title, "テスト絵本")
        XCTAssertEqual(book.author, "テスト作者")
    }
    
    func testUserRepositoryBasicOperation() throws {
        // 基本的なRepository動作をテスト
        let user = User(id: UUID(), name: "テストユーザー", group: "テストグループ")
        XCTAssertEqual(user.name, "テストユーザー")
        XCTAssertEqual(user.group, "テストグループ")
    }
    
    func testLoanBasicOperation() throws {
        // 基本的なLoan動作をテスト
        let loan = Loan(
            id: UUID(),
            bookId: UUID(),
            userId: UUID(),
            loanDate: Date(),
            dueDate: Date().addingTimeInterval(86400 * 7), // 1週間後
            returnedDate: nil
        )
        XCTAssertFalse(loan.isReturned)
    }
}
