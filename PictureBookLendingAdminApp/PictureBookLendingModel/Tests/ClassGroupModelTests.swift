import Foundation
import PictureBookLendingDomain
import Testing

@testable import PictureBookLendingModel

/// ClassGroupModelテストケース
///
/// クラス（組）管理モデルの各機能をテストするためのケース集です。
/// - クラスの登録
/// - クラスの一覧取得
/// - クラスのID検索
/// - クラス情報の更新
/// - クラスの削除
/// - 年度別・年齢別検索
/// などの機能をテストします。
@Suite("ClassGroupModel Tests")
struct ClassGroupModelTests {
    
    @MainActor
    private func createClassGroupModel() -> (ClassGroupModel, MockClassGroupRepository) {
        let mockRepository = MockClassGroupRepository()
        let classGroupModel = ClassGroupModel(repository: mockRepository)
        return (classGroupModel, mockRepository)
    }
    
    /// クラス登録機能のテスト
    ///
    /// 新しいクラスを登録し、正しく登録されることを確認します。
    @Test("クラス登録機能")
    @MainActor
    func registerClassGroup() throws {
        // 1. Arrange - 準備
        let (classGroupModel, _) = createClassGroupModel()
        let classGroup = ClassGroup(
            name: "ひよこ組", ageGroup: AgeGroup.age(0), year: 2025)
        
        // 2. Act - 実行
        try classGroupModel.registerClassGroup(classGroup)
        
        // 3. Assert - 検証
        let classGroups = classGroupModel.getAllClassGroups()
        #expect(classGroups.count == 1)
        #expect(classGroups.first?.name == "ひよこ組")
        #expect(classGroups.first?.ageGroup == AgeGroup.age(0))
        #expect(classGroups.first?.year == 2025)
    }
    
    /// 全クラス取得機能のテスト
    ///
    /// 複数のクラスを登録し、全てのクラスが取得できることを確認します。
    @Test("全クラス取得機能")
    @MainActor
    func getAllClassGroups() throws {
        // 1. Arrange - 準備
        let (classGroupModel, _) = createClassGroupModel()
        let classGroup1 = ClassGroup(
            name: "ひよこ組", ageGroup: AgeGroup.age(0), year: 2025)
        let classGroup2 = ClassGroup(
            name: "りす組", ageGroup: AgeGroup.age(1), year: 2025)
        
        // 2. Act - 実行
        try classGroupModel.registerClassGroup(classGroup1)
        try classGroupModel.registerClassGroup(classGroup2)
        let classGroups = classGroupModel.getAllClassGroups()
        
        // 3. Assert - 検証
        #expect(classGroups.count == 2)
        #expect(Set(classGroups.map { $0.name }) == Set(["ひよこ組", "りす組"]))
    }
    
    /// クラスID検索機能のテスト
    ///
    /// IDを指定してクラスを検索し、正しいクラスが取得できることを確認します。
    @Test("クラスID検索機能")
    @MainActor
    func findClassGroupById() throws {
        // 1. Arrange - 準備
        let (classGroupModel, _) = createClassGroupModel()
        let classGroup = ClassGroup(
            name: "ひよこ組", ageGroup: AgeGroup.age(0), year: 2025)
        try classGroupModel.registerClassGroup(classGroup)
        let id = classGroup.id
        
        // 2. Act - 実行
        let foundClassGroup = classGroupModel.findClassGroupById(id)
        
        // 3. Assert - 検証
        #expect(foundClassGroup != nil)
        #expect(foundClassGroup?.name == "ひよこ組")
        #expect(foundClassGroup?.ageGroup == AgeGroup.age(0))
        #expect(foundClassGroup?.year == 2025)
    }
    
    /// クラス更新機能のテスト
    ///
    /// 登録済みのクラス情報を更新し、正しく更新されることを確認します。
    @Test("クラス更新機能")
    @MainActor
    func updateClassGroup() throws {
        // 1. Arrange - 準備
        let (classGroupModel, _) = createClassGroupModel()
        let classGroup = ClassGroup(
            name: "ひよこ組", ageGroup: AgeGroup.age(0), year: 2025)
        try classGroupModel.registerClassGroup(classGroup)
        
        var updatedClassGroup = classGroup
        updatedClassGroup.name = "ひよこ組改名版"
        
        // 2. Act - 実行
        try classGroupModel.updateClassGroup(updatedClassGroup)
        
        // 3. Assert - 検証
        let classGroups = classGroupModel.getAllClassGroups()
        #expect(classGroups.count == 1)
        let foundClassGroup = classGroupModel.findClassGroupById(classGroup.id)
        #expect(foundClassGroup?.name == "ひよこ組改名版")
    }
    
    /// クラス削除機能のテスト
    ///
    /// 登録済みのクラスを削除し、正しく削除されることを確認します。
    @Test("クラス削除機能")
    @MainActor
    func deleteClassGroup() throws {
        // 1. Arrange - 準備
        let (classGroupModel, _) = createClassGroupModel()
        let classGroup = ClassGroup(
            name: "ひよこ組", ageGroup: AgeGroup.age(0), year: 2025)
        try classGroupModel.registerClassGroup(classGroup)
        let id = classGroup.id
        
        // 2. Act - 実行
        try classGroupModel.deleteClassGroup(id)
        
        // 3. Assert - 検証
        let classGroups = classGroupModel.getAllClassGroups()
        #expect(classGroups.count == 0)
        let foundClassGroup = classGroupModel.findClassGroupById(id)
        #expect(foundClassGroup == nil)
    }
    
    /// クラス一覧ロード機能のテスト
    ///
    /// リポジトリからクラス一覧をロードし、正しくキャッシュされることを確認します。
    @Test("クラス一覧ロード機能")
    @MainActor
    func loadAllClassGroups() throws {
        // 1. Arrange - 準備
        let (classGroupModel, repository) = createClassGroupModel()
        let classGroup = ClassGroup(
            name: "ひよこ組", ageGroup: AgeGroup.age(0), year: 2025)
        try repository.save(classGroup)
        
        // 2. Act - 実行
        // loadAllClassGroups メソッドがないため、refreshClassGroups を使用
        classGroupModel.refreshClassGroups()
        
        // 3. Assert - 検証
        let classGroups = classGroupModel.getAllClassGroups()
        #expect(classGroups.count == 1)
        #expect(classGroups.first?.name == "ひよこ組")
    }
    
    /// クラス一覧リフレッシュ機能のテスト
    ///
    /// キャッシュをリフレッシュし、最新データが取得されることを確認します。
    @Test("クラス一覧リフレッシュ機能")
    @MainActor
    func refreshClassGroups() throws {
        // 1. Arrange - 準備
        let (classGroupModel, repository) = createClassGroupModel()
        
        // 最初は空
        #expect(classGroupModel.getAllClassGroups().count == 0)
        
        // リポジトリに直接データを追加
        let classGroup = ClassGroup(
            name: "ひよこ組", ageGroup: AgeGroup.age(0), year: 2025)
        try repository.save(classGroup)
        
        // 2. Act - 実行
        classGroupModel.refreshClassGroups()
        
        // 3. Assert - 検証
        let classGroups = classGroupModel.getAllClassGroups()
        #expect(classGroups.count == 1)
        #expect(classGroups.first?.name == "ひよこ組")
    }
    
    // MARK: - 卒業クラスの事前確認（graduatingClassGroups）
    
    /// 進級で卒業となるクラスだけが返ることのテスト
    ///
    /// 進級処理の確認ダイアログで「どの組がいなくなるか」を事前に示すために使います。
    @Test("進級で卒業となるクラスのみが返ること")
    @MainActor
    func graduatingClassGroupsReturnsOnlyOldestClass() throws {
        // 1. Arrange - 準備
        let (classGroupModel, _) = createClassGroupModel()
        for age in 0...5 {
            try classGroupModel.registerClassGroup(
                ClassGroup(name: "\(age)歳児組", ageGroup: AgeGroup.age(age), year: 2025))
        }
        
        // 2. Act - 実行
        let graduating = classGroupModel.graduatingClassGroups()
        
        // 3. Assert - 検証
        #expect(graduating.count == 1)
        #expect(graduating.first?.ageGroup == AgeGroup.age(5), "5歳児クラスのみが卒業となる")
    }
    
    /// 「その他」の組が卒業扱いにならないことのテスト
    @Test("その他の組が卒業扱いにならないこと")
    @MainActor
    func graduatingClassGroupsExcludesOtherAgeGroup() throws {
        // 1. Arrange - 準備
        let (classGroupModel, _) = createClassGroupModel()
        try classGroupModel.registerClassGroup(
            ClassGroup(name: "未分類", ageGroup: AgeGroup.other, year: 2025))
        
        // 2. Act - 実行
        let graduating = classGroupModel.graduatingClassGroups()
        
        // 3. Assert - 検証
        #expect(graduating.isEmpty)
    }
    
    /// 卒業クラスが `promoteToNextYear()` で実際に削除される組と一致することのテスト
    ///
    /// 事前確認と実処理がズレると、ダイアログの予告が嘘になるため
    @Test("卒業クラスの事前確認が進級処理の結果と一致すること")
    @MainActor
    func graduatingClassGroupsMatchesPromoteResult() throws {
        // 1. Arrange - 準備
        let (classGroupModel, _) = createClassGroupModel()
        for age in 0...5 {
            try classGroupModel.registerClassGroup(
                ClassGroup(name: "\(age)歳児組", ageGroup: AgeGroup.age(age), year: 2025))
        }
        let expected = classGroupModel.graduatingClassGroups()
        
        // 2. Act - 実行
        let deleted = try classGroupModel.promoteToNextYear()
        
        // 3. Assert - 検証
        #expect(Set(deleted.map(\.id)) == Set(expected.map(\.id)))
    }
}
