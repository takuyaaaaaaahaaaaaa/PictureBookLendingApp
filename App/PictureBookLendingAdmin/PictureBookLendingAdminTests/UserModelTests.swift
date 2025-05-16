import XCTest
import PictureBookLendingCore
@testable import PictureBookLendingAdmin

/**
 * UserModelテストケース
 *
 * 利用者管理モデルの各機能をテストするためのケース集です。
 * - 利用者の登録
 * - 利用者の一覧取得
 * - 利用者のID検索
 * - 利用者情報の更新
 * - 利用者の削除
 * などの機能をテストします。
 */
final class UserModelTests: XCTestCase {
    
    /**
     * 利用者登録機能のテスト
     *
     * 新しい利用者を登録し、正しく登録されることを確認します。
     */
    func testRegisterUser() throws {
        // 1. Arrange - 準備
        let userModel = UserModel()
        let user = User(name: "山田太郎", group: "1年2組")
        
        // 2. Act - 実行
        let registeredUser = try userModel.registerUser(user)
        
        // 3. Assert - 検証
        XCTAssertEqual(registeredUser.name, "山田太郎")
        XCTAssertEqual(registeredUser.group, "1年2組")
        XCTAssertNotNil(registeredUser.id)
        XCTAssertEqual(userModel.users.count, 1)
    }
    
    /**
     * 全利用者取得機能のテスト
     *
     * 複数の利用者を登録し、全ての利用者が取得できることを確認します。
     */
    func testGetAllUsers() throws {
        // 1. Arrange - 準備
        let userModel = UserModel()
        let user1 = User(name: "山田太郎", group: "1年2組")
        let user2 = User(name: "鈴木花子", group: "2年1組")
        
        // 2. Act - 実行
        try userModel.registerUser(user1)
        try userModel.registerUser(user2)
        let users = userModel.getAllUsers()
        
        // 3. Assert - 検証
        XCTAssertEqual(users.count, 2)
        XCTAssertEqual(Set(users.map { $0.name }), Set(["山田太郎", "鈴木花子"]))
    }
    
    /**
     * 利用者ID検索機能のテスト
     *
     * IDを指定して利用者を検索し、正しい利用者が取得できることを確認します。
     */
    func testFindUserById() throws {
        // 1. Arrange - 準備
        let userModel = UserModel()
        let user = User(name: "山田太郎", group: "1年2組")
        let registeredUser = try userModel.registerUser(user)
        let id = registeredUser.id
        
        // 2. Act - 実行
        let foundUser = userModel.findUserById(id)
        
        // 3. Assert - 検証
        XCTAssertNotNil(foundUser)
        XCTAssertEqual(foundUser?.name, "山田太郎")
    }
    
    /**
     * 利用者更新機能のテスト
     *
     * 登録済みの利用者情報を更新し、正しく更新されることを確認します。
     */
    func testUpdateUser() throws {
        // 1. Arrange - 準備
        let userModel = UserModel()
        let user = User(name: "山田太郎", group: "1年2組")
        let registeredUser = try userModel.registerUser(user)
        let id = registeredUser.id
        
        let updatedUserInfo = User(id: id, name: "山田次郎", group: "1年2組")
        
        // 2. Act - 実行
        let updatedUser = try userModel.updateUser(updatedUserInfo)
        
        // 3. Assert - 検証
        XCTAssertEqual(updatedUser.name, "山田次郎")
        XCTAssertEqual(updatedUser.group, "1年2組")
        XCTAssertEqual(userModel.users.count, 1) // 数は変わらない
        XCTAssertEqual(userModel.findUserById(id)?.name, "山田次郎")
    }
    
    /**
     * 利用者削除機能のテスト
     *
     * 登録済みの利用者を削除し、正しく削除されることを確認します。
     */
    func testDeleteUser() throws {
        // 1. Arrange - 準備
        let userModel = UserModel()
        let user = User(name: "山田太郎", group: "1年2組")
        let registeredUser = try userModel.registerUser(user)
        let id = registeredUser.id
        
        // 2. Act - 実行
        let result = try userModel.deleteUser(id)
        
        // 3. Assert - 検証
        XCTAssertTrue(result)
        XCTAssertEqual(userModel.users.count, 0)
        XCTAssertNil(userModel.findUserById(id))
    }
    
    /**
     * 存在しない利用者削除時のエラーテスト
     *
     * 存在しない利用者IDを指定して削除を試みた場合、適切なエラーが発生することを確認します。
     */
    func testDeleteNonExistingUser() throws {
        // 1. Arrange - 準備
        let userModel = UserModel()
        let nonExistingId = UUID()
        
        // 2. Act & Assert - 実行と検証
        XCTAssertThrowsError(try userModel.deleteUser(nonExistingId)) { error in
            XCTAssertEqual(error as? UserModelError, UserModelError.userNotFound)
        }
    }
}