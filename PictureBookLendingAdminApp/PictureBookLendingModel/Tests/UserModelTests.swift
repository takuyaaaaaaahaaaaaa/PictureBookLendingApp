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
    
    @MainActor
    private func createUserModel() -> (UserModel, MockUserRepository) {
        let mockRepository = MockUserRepository()
        let userModel = UserModel(repository: mockRepository)
        return (userModel, mockRepository)
    }
    
    /// 利用者登録機能のテスト
    ///
    /// 新しい利用者を登録し、正しく登録されることを確認します。
    @Test("利用者登録機能のテスト")
    @MainActor
    func registerUser() throws {
        // 1. Arrange - 準備
        let (userModel, _) = createUserModel()
        let classGroupId = UUID()
        let user = User(name: "山田太郎", classGroupId: classGroupId)
        
        // 2. Act - 実行
        let registeredUser = try userModel.registerUser(user)
        
        // 3. Assert - 検証
        #expect(registeredUser.name == "山田太郎")
        #expect(registeredUser.classGroupId == classGroupId)
        #expect(!registeredUser.id.uuidString.isEmpty)
        #expect(userModel.users.count == 1)
    }
    
    /// 全利用者取得機能のテスト
    ///
    /// 複数の利用者を登録し、全ての利用者が取得できることを確認します。
    @Test("全利用者取得機能のテスト")
    @MainActor
    func getAllUsers() throws {
        // 1. Arrange - 準備
        let (userModel, _) = createUserModel()
        let classGroupId1 = UUID()
        let classGroupId2 = UUID()
        let user1 = User(name: "山田太郎", classGroupId: classGroupId1)
        let user2 = User(name: "鈴木花子", classGroupId: classGroupId2)
        
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
    @MainActor
    func findUserById() throws {
        // 1. Arrange - 準備
        let (userModel, _) = createUserModel()
        let classGroupId = UUID()
        let user = User(name: "山田太郎", classGroupId: classGroupId)
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
    @MainActor
    func updateUser() throws {
        // 1. Arrange - 準備
        let (userModel, _) = createUserModel()
        let classGroupId = UUID()
        let user = User(name: "山田太郎", classGroupId: classGroupId)
        let registeredUser = try userModel.registerUser(user)
        let id = registeredUser.id
        
        let updatedUserInfo = User(id: id, name: "山田次郎", classGroupId: classGroupId)
        
        // 2. Act - 実行
        let updatedUser = try userModel.updateUser(updatedUserInfo)
        
        // 3. Assert - 検証
        #expect(updatedUser.name == "山田次郎")
        #expect(updatedUser.classGroupId == classGroupId)
        #expect(userModel.users.count == 1)  // 数は変わらない
        #expect(userModel.findUserById(id)?.name == "山田次郎")
    }
    
    /// 利用者削除機能のテスト
    ///
    /// 登録済みの利用者を削除し、正しく削除されることを確認します。
    @Test("利用者削除機能のテスト")
    @MainActor
    func deleteUser() throws {
        // 1. Arrange - 準備
        let (userModel, _) = createUserModel()
        let classGroupId = UUID()
        let user = User(name: "山田太郎", classGroupId: classGroupId)
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
    @MainActor
    func deleteNonExistingUser() throws {
        // 1. Arrange - 準備
        let (userModel, _) = createUserModel()
        let nonExistingId = UUID()
        
        // 2. Act & Assert - 実行と検証
        #expect(throws: UserModelError.userNotFound) {
            try userModel.deleteUser(nonExistingId)
        }
    }
    
    // MARK: - 家庭解決（getFamilyMembers）
    
    /// 園児IDから家族全員（本人＋保護者）を取得できることのテスト
    @Test("園児IDから家族全員を取得できることのテスト")
    @MainActor
    func getFamilyMembersFromChild() throws {
        let (userModel, _) = createUserModel()
        let classGroupId = UUID()
        let child = try userModel.registerUser(User(name: "いとう さくら", classGroupId: classGroupId))
        let mother = try userModel.registerUser(
            User(
                name: "伊藤 由美子", classGroupId: classGroupId,
                userType: .guardian(relatedChildId: child.id)))
        let father = try userModel.registerUser(
            User(
                name: "伊藤 健一", classGroupId: classGroupId,
                userType: .guardian(relatedChildId: child.id)))
        
        let family = userModel.getFamilyMembers(of: child.id)
        
        #expect(family.count == 3)
        #expect(family.first?.id == child.id, "園児が先頭に来る")
        #expect(family.contains(where: { $0.id == mother.id }))
        #expect(family.contains(where: { $0.id == father.id }))
    }
    
    /// 保護者IDからも同じ家族に解決されることのテスト
    @Test("保護者IDからも同じ家族に解決されることのテスト")
    @MainActor
    func getFamilyMembersFromGuardian() throws {
        let (userModel, _) = createUserModel()
        let classGroupId = UUID()
        let child = try userModel.registerUser(User(name: "いとう さくら", classGroupId: classGroupId))
        let mother = try userModel.registerUser(
            User(
                name: "伊藤 由美子", classGroupId: classGroupId,
                userType: .guardian(relatedChildId: child.id)))
        
        let familyFromChild = userModel.getFamilyMembers(of: child.id)
        let familyFromGuardian = userModel.getFamilyMembers(of: mother.id)
        
        #expect(familyFromChild.map(\.id) == familyFromGuardian.map(\.id), "どの家族名から入っても同じ家庭に着地する")
    }
    
    /// 保護者が登録されていない園児は本人のみ返ることのテスト
    @Test("保護者が未登録の園児は本人のみ返ることのテスト")
    @MainActor
    func getFamilyMembersChildOnly() throws {
        let (userModel, _) = createUserModel()
        let child = try userModel.registerUser(User(name: "あおき はると", classGroupId: UUID()))
        
        let family = userModel.getFamilyMembers(of: child.id)
        
        #expect(family.map(\.id) == [child.id])
    }
    
    /// 存在しない利用者IDでは空配列が返ることのテスト
    @Test("存在しない利用者IDでは空配列が返ることのテスト")
    @MainActor
    func getFamilyMembersUnknownId() {
        let (userModel, _) = createUserModel()
        
        let family = userModel.getFamilyMembers(of: UUID())
        
        #expect(family.isEmpty)
    }
    
    /// 園児を削除すると保護者もカスケード削除され、家庭解決が空になることのテスト
    ///
    /// `deleteUser` のドメイン仕様（園児削除で関連保護者も削除）により、
    /// 「紐付く園児のいない保護者」は正規操作では発生しない。
    @Test("園児削除で保護者も削除され家庭解決が空になることのテスト")
    @MainActor
    func getFamilyMembersAfterChildDeleted() throws {
        let (userModel, _) = createUserModel()
        let classGroupId = UUID()
        let child = try userModel.registerUser(User(name: "いとう さくら", classGroupId: classGroupId))
        let mother = try userModel.registerUser(
            User(
                name: "伊藤 由美子", classGroupId: classGroupId,
                userType: .guardian(relatedChildId: child.id)))
        
        _ = try userModel.deleteUser(child.id)
        
        #expect(userModel.findUserById(mother.id) == nil, "園児削除で保護者もカスケード削除される（仕様）")
        #expect(userModel.getFamilyMembers(of: mother.id).isEmpty)
    }
    
    // MARK: - 家庭の代表解決（familyRepresentative）
    
    /// 園児IDを渡すと自分自身が返ることのテスト
    @Test("園児IDを渡すと自分自身が返ることのテスト")
    @MainActor
    func familyRepresentativeFromChild() throws {
        let (userModel, _) = createUserModel()
        let classGroupId = UUID()
        let child = try userModel.registerUser(User(name: "いとう さくら", classGroupId: classGroupId))
        _ = try userModel.registerUser(
            User(
                name: "伊藤 由美子", classGroupId: classGroupId,
                userType: .guardian(relatedChildId: child.id)))
        
        let representative = userModel.familyRepresentative(of: child.id)
        
        #expect(representative?.id == child.id)
    }
    
    /// 保護者IDを渡すと紐づく園児が返ることのテスト
    @Test("保護者IDを渡すと紐づく園児が返ることのテスト")
    @MainActor
    func familyRepresentativeFromGuardian() throws {
        let (userModel, _) = createUserModel()
        let classGroupId = UUID()
        let child = try userModel.registerUser(User(name: "いとう さくら", classGroupId: classGroupId))
        let mother = try userModel.registerUser(
            User(
                name: "伊藤 由美子", classGroupId: classGroupId,
                userType: .guardian(relatedChildId: child.id)))
        
        let representative = userModel.familyRepresentative(of: mother.id)
        
        #expect(representative?.id == child.id)
    }
    
    /// 紐づく園児が存在しない保護者IDを渡すと本人が返ることのテスト
    @Test("紐づく園児が存在しない保護者IDを渡すと本人が返ることのテスト")
    @MainActor
    func familyRepresentativeGuardianWithoutChild() throws {
        let (userModel, _) = createUserModel()
        let classGroupId = UUID()
        let orphanGuardian = try userModel.registerUser(
            User(
                name: "孤立 保護者", classGroupId: classGroupId,
                userType: .guardian(relatedChildId: UUID())))
        
        let representative = userModel.familyRepresentative(of: orphanGuardian.id)
        
        #expect(representative?.id == orphanGuardian.id)
    }
    
    /// 存在しないIDを渡すとnilが返ることのテスト
    @Test("存在しない利用者IDではnilが返ることのテスト")
    @MainActor
    func familyRepresentativeUnknownId() {
        let (userModel, _) = createUserModel()
        
        let representative = userModel.familyRepresentative(of: UUID())
        
        #expect(representative == nil)
    }
    
    // MARK: - 一覧の入口となる利用者（getFamilyEntranceUsers）
    
    /// 園児と保護者がいる家庭では園児のみが返ることのテスト
    @Test("園児と保護者がいる家庭では園児のみが返ることのテスト")
    @MainActor
    func getFamilyEntranceUsersHidesGuardianWithChild() throws {
        let (userModel, _) = createUserModel()
        let classGroupId = UUID()
        let child = try userModel.registerUser(User(name: "いとう さくら", classGroupId: classGroupId))
        _ = try userModel.registerUser(
            User(
                name: "伊藤 由美子", classGroupId: classGroupId,
                userType: .guardian(relatedChildId: child.id)))
        
        let entranceUsers = userModel.getFamilyEntranceUsers()
        
        #expect(entranceUsers.map(\.id) == [child.id])
    }
    
    /// 紐づく園児がいない保護者は一覧に含まれることのテスト
    @Test("紐づく園児がいない保護者は一覧に含まれることのテスト")
    @MainActor
    func getFamilyEntranceUsersIncludesOrphanGuardian() throws {
        let (userModel, _) = createUserModel()
        let classGroupId = UUID()
        let orphanGuardian = try userModel.registerUser(
            User(
                name: "孤立 保護者", classGroupId: classGroupId,
                userType: .guardian(relatedChildId: UUID())))
        
        let entranceUsers = userModel.getFamilyEntranceUsers()
        
        #expect(entranceUsers.map(\.id) == [orphanGuardian.id])
    }
    
    /// 園児でも保護者でもない単独利用者（先生等）は一覧に含まれることのテスト
    @Test("園児でも保護者でもない単独利用者は一覧に含まれることのテスト")
    @MainActor
    func getFamilyEntranceUsersIncludesStandaloneUser() throws {
        let (userModel, _) = createUserModel()
        let teacher = try userModel.registerUser(User(name: "先生", classGroupId: UUID()))
        
        let entranceUsers = userModel.getFamilyEntranceUsers()
        
        #expect(entranceUsers.map(\.id) == [teacher.id])
    }
}
