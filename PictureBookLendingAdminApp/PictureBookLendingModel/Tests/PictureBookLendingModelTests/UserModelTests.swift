import Foundation
import PictureBookLendingDomain
import Testing

@testable import PictureBookLendingModel

/// UserModelテストケース
///
/// 利用者管理モデルの各機能をテストするためのケース集です。
/// - 利用者の登録
/// - 利用者の一覧取得
/// - 利用者のID検索
/// - 利用者情報の更新
/// - 利用者の削除
/// などの機能をテストします。
@Suite("UserModel Tests")
struct UserModelTests {
    
    private func createUserModel() -> (UserModel, MockUserRepository) {
        let mockRepository = MockUserRepository()
        let userModel = UserModel(repository: mockRepository)
        return (userModel, mockRepository)
    }
    
    /// 利用者登録機能のテスト
    ///
    /// 新しい利用者を登録し、正しく登録されることを確認します。
    @Test("利用者登録機能のテスト")
    func registerUser() throws {
        // 1. Arrange - 準備
        let (userModel, _) = createUserModel()
        let user = User(name: "山田太郎", group: "1年2組")
        
        // 2. Act - 実行
        let registeredUser = try userModel.registerUser(user)
        
        // 3. Assert - 検証
        #expect(registeredUser.name == "山田太郎")
        #expect(registeredUser.group == "1年2組")
        #expect(!registeredUser.id.uuidString.isEmpty)
        #expect(userModel.users.count == 1)
    }
    
    /// 全利用者取得機能のテスト
    ///
    /// 複数の利用者を登録し、全ての利用者が取得できることを確認します。
    @Test("全利用者取得機能のテスト")
    func getAllUsers() throws {
        // 1. Arrange - 準備
        let (userModel, _) = createUserModel()
        let user1 = User(name: "山田太郎", group: "1年2組")
        let user2 = User(name: "鈴木花子", group: "2年1組")
        
        // 2. Act - 実行
        _ = try userModel.registerUser(user1)
        _ = try userModel.registerUser(user2)
        let users = userModel.getAllUsers()
        
        // 3. Assert - 検証
        #expect(users.count == 2)
        #expect(Set(users.map { $0.name }) == Set(["山田太郎", "鈴木花子"]))
    }
    
    /// 利用者ID検索機能のテスト
    ///
    /// IDを指定して利用者を検索し、正しい利用者が取得できることを確認します。
    @Test("利用者ID検索機能のテスト")
    func findUserById() throws {
        // 1. Arrange - 準備
        let (userModel, _) = createUserModel()
        let user = User(name: "山田太郎", group: "1年2組")
        let registeredUser = try userModel.registerUser(user)
        let id = registeredUser.id
        
        // 2. Act - 実行
        let foundUser = userModel.findUserById(id)
        
        // 3. Assert - 検証
        #expect(foundUser != nil)
        #expect(foundUser?.name == "山田太郎")
    }
    
    /// 利用者更新機能のテスト
    ///
    /// 登録済みの利用者情報を更新し、正しく更新されることを確認します。
    @Test("利用者更新機能のテスト")
    func updateUser() throws {
        // 1. Arrange - 準備
        let (userModel, _) = createUserModel()
        let user = User(name: "山田太郎", group: "1年2組")
        let registeredUser = try userModel.registerUser(user)
        let id = registeredUser.id
        
        let updatedUserInfo = User(id: id, name: "山田次郎", group: "1年2組")
        
        // 2. Act - 実行
        let updatedUser = try userModel.updateUser(updatedUserInfo)
        
        // 3. Assert - 検証
        #expect(updatedUser.name == "山田次郎")
        #expect(updatedUser.group == "1年2組")
        #expect(userModel.users.count == 1)  // 数は変わらない
        #expect(userModel.findUserById(id)?.name == "山田次郎")
    }
    
    /// 利用者削除機能のテスト
    ///
    /// 登録済みの利用者を削除し、正しく削除されることを確認します。
    @Test("利用者削除機能のテスト")
    func deleteUser() throws {
        // 1. Arrange - 準備
        let (userModel, _) = createUserModel()
        let user = User(name: "山田太郎", group: "1年2組")
        let registeredUser = try userModel.registerUser(user)
        let id = registeredUser.id
        
        // 2. Act - 実行
        let result = try userModel.deleteUser(id)
        
        // 3. Assert - 検証
        #expect(result == true)
        #expect(userModel.users.count == 0)
        #expect(userModel.findUserById(id) == nil)
    }
    
    /// 存在しない利用者削除時のエラーテスト
    ///
    /// 存在しない利用者IDを指定して削除を試みた場合、適切なエラーが発生することを確認します。
    @Test("存在しない利用者削除時のエラーテスト")
    func deleteNonExistingUser() throws {
        // 1. Arrange - 準備
        let (userModel, _) = createUserModel()
        let nonExistingId = UUID()
        
        // 2. Act & Assert - 実行と検証
        #expect(throws: UserModelError.userNotFound) {
            try userModel.deleteUser(nonExistingId)
        }
    }
}
