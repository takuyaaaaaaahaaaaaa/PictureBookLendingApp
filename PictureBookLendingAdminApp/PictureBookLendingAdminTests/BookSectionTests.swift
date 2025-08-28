import Foundation
import PictureBookLendingDomain
import PictureBookLendingUI
import Testing

@testable import PictureBookLendingAdmin

/// BookSection拡張メソッドテストケース
///
/// BookSection+sortedで定義された以下の機能をテストします：
/// - セクション作成機能（createSections）
/// - フィルタリング機能（filtered）
/// - ソート機能（sorted）
@Suite("BookSection Extension Tests")
struct BookSectionTests {
    
    // MARK: - Test Data
    
    private var testBooks: [Book] {
        [
            Book(title: "あいうえお", author: "作者A", managementNumber: "あ001", kanaGroup: .a),
            Book(title: "いろはにほへと", author: "作者B", managementNumber: "あ002", kanaGroup: .a),
            Book(title: "かきくけこ", author: "作者C", managementNumber: "か010", kanaGroup: .ka),
            Book(title: "きつねとたぬき", author: "作者D", managementNumber: "か002", kanaGroup: .ka),
            Book(title: "はらぺこあおむし", author: "エリック・カール", managementNumber: "は001", kanaGroup: .ha),
            Book(title: "ひまわり", author: "作者E", managementNumber: nil, kanaGroup: .ha),
            Book(title: "その他の本", author: "作者F", managementNumber: "999", kanaGroup: nil),
        ]
    }
    
    // MARK: - createSections Tests
    
    /// セクション作成機能のテスト
    ///
    /// 絵本データから五十音グループごとのセクションを正しく作成できることを確認します。
    @Test("セクション作成機能")
    func createSections() {
        // 1. Arrange - 準備
        let books = testBooks
        
        // 2. Act - 実行
        let sections = BookSection.createSections(from: books)
        
        // 3. Assert - 検証
        #expect(sections.count == 4)  // あ、か、は、その他
        
        // 五十音順にソートされていることを確認
        let kanaGroups = sections.map { $0.kanaGroup }
        let expectedOrder: [KanaGroup?] = [.a, .ka, .ha, .other]
        #expect(kanaGroups.compactMap { $0 } == expectedOrder.compactMap { $0 })
        
        // 各セクションの本の数を確認
        let aSection = sections.first { $0.kanaGroup == .a }!
        #expect(aSection.books.count == 2)
        
        let kaSection = sections.first { $0.kanaGroup == .ka }!
        #expect(kaSection.books.count == 2)
        
        let haSection = sections.first { $0.kanaGroup == .ha }!
        #expect(haSection.books.count == 2)
        
        let otherSection = sections.first { $0.kanaGroup == .other }!
        #expect(otherSection.books.count == 1)
    }
    
    /// 空データでのセクション作成テスト
    ///
    /// 空の絵本配列から空のセクション配列が作成されることを確認します。
    @Test("空データでのセクション作成")
    func createSectionsEmpty() {
        // 1. Arrange - 準備
        let books: [Book] = []
        
        // 2. Act - 実行
        let sections = BookSection.createSections(from: books)
        
        // 3. Assert - 検証
        #expect(sections.count == 0)
    }
    
    // MARK: - filtered Tests
    
    /// 検索テキストによるフィルタリングテスト
    ///
    /// タイトルでの検索フィルタリングが正しく動作することを確認します。
    @Test("検索テキストによるフィルタリング")
    func filteredBySearchText() {
        // 1. Arrange - 準備
        let sections = BookSection.createSections(from: testBooks)
        
        // 2. Act - 実行（"あおむし"で検索）
        let filteredSections = BookSection.filtered(
            sections: sections,
            searchText: "あおむし",
            selectedKanaFilter: nil
        )
        
        // 3. Assert - 検証
        #expect(filteredSections.count == 1)
        #expect(filteredSections[0].kanaGroup == .ha)
        #expect(filteredSections[0].books.count == 1)
        #expect(filteredSections[0].books[0].title == "はらぺこあおむし")
    }
    
    /// 著者名による検索フィルタリングテスト
    ///
    /// 著者名での検索フィルタリングが正しく動作することを確認します。
    @Test("著者名による検索フィルタリング")
    func filteredByAuthor() {
        // 1. Arrange - 準備
        let sections = BookSection.createSections(from: testBooks)
        
        // 2. Act - 実行（"エリック・カール"で検索）
        let filteredSections = BookSection.filtered(
            sections: sections,
            searchText: "エリック・カール",
            selectedKanaFilter: nil
        )
        
        // 3. Assert - 検証
        #expect(filteredSections.count == 1)
        #expect(filteredSections[0].books[0].author == "エリック・カール")
    }
    
    /// 五十音グループによるフィルタリングテスト
    ///
    /// 特定の五十音グループでのフィルタリングが正しく動作することを確認します。
    @Test("五十音グループによるフィルタリング")
    func filteredByKanaGroup() {
        // 1. Arrange - 準備
        let sections = BookSection.createSections(from: testBooks)
        
        // 2. Act - 実行（か行のみ）
        let filteredSections = BookSection.filtered(
            sections: sections,
            searchText: "",
            selectedKanaFilter: .ka
        )
        
        // 3. Assert - 検証
        #expect(filteredSections.count == 1)
        #expect(filteredSections[0].kanaGroup == .ka)
        #expect(filteredSections[0].books.count == 2)
    }
    
    /// 複合フィルタリングテスト
    ///
    /// 検索テキストと五十音グループの両方でのフィルタリングが正しく動作することを確認します。
    @Test("複合フィルタリング")
    func filteredBySearchTextAndKanaGroup() {
        // 1. Arrange - 準備
        let sections = BookSection.createSections(from: testBooks)
        
        // 2. Act - 実行（"か"で検索 + か行フィルター）
        let filteredSections = BookSection.filtered(
            sections: sections,
            searchText: "か",
            selectedKanaFilter: .ka
        )
        
        // 3. Assert - 検証
        #expect(filteredSections.count == 1)
        #expect(filteredSections[0].kanaGroup == .ka)
        #expect(filteredSections[0].books.count == 1)
        #expect(filteredSections[0].books[0].title == "かきくけこ")
    }
    
    /// フィルタリング結果なしテスト
    ///
    /// 該当する絵本がない検索でセクションが空になることを確認します。
    @Test("フィルタリング結果なし")
    func filteredNoResults() {
        // 1. Arrange - 準備
        let sections = BookSection.createSections(from: testBooks)
        
        // 2. Act - 実行（存在しない文字列で検索）
        let filteredSections = BookSection.filtered(
            sections: sections,
            searchText: "存在しない本",
            selectedKanaFilter: nil
        )
        
        // 3. Assert - 検証
        #expect(filteredSections.count == 0)
    }
    
    // MARK: - sorted Tests
    
    /// タイトルソートテスト
    ///
    /// タイトルのあいうえお順ソートが正しく動作することを確認します。
    @Test("タイトルソート")
    func sortedByTitle() {
        // 1. Arrange - 準備
        let sections = BookSection.createSections(from: testBooks)
        let kaSection = sections.first { $0.kanaGroup == .ka }!
        
        // 2. Act - 実行
        let sortedSections = BookSection.sorted(sections: [kaSection], by: .title)
        
        // 3. Assert - 検証
        #expect(sortedSections.count == 1)
        let books = sortedSections[0].books
        #expect(books[0].title == "かきくけこ")  // あいうえお順で最初
        #expect(books[1].title == "きつねとたぬき")  // あいうえお順で2番目
    }
    
    /// 管理番号ソートテスト
    ///
    /// 管理番号順ソートが正しく動作することを確認します。
    @Test("管理番号ソート")
    func sortedByManagementNumber() {
        // 1. Arrange - 準備
        let sections = BookSection.createSections(from: testBooks)
        let aSection = sections.first { $0.kanaGroup == .a }!
        
        // 2. Act - 実行
        let sortedSections = BookSection.sorted(sections: [aSection], by: .managementNumber)
        
        // 3. Assert - 検証
        #expect(sortedSections.count == 1)
        let books = sortedSections[0].books
        #expect(books[0].managementNumber == "あ001")  // 番号順で最初
        #expect(books[1].managementNumber == "あ002")  // 番号順で2番目
    }
    
    /// 管理番号なしを含むソートテスト
    ///
    /// 管理番号がない絵本を含むソートで、管理番号なしが最後に配置されることを確認します。
    @Test("管理番号なしを含むソート")
    func sortedByManagementNumberWithNil() {
        // 1. Arrange - 準備
        let sections = BookSection.createSections(from: testBooks)
        let haSection = sections.first { $0.kanaGroup == .ha }!
        
        // 2. Act - 実行
        let sortedSections = BookSection.sorted(sections: [haSection], by: .managementNumber)
        
        // 3. Assert - 検証
        #expect(sortedSections.count == 1)
        let books = sortedSections[0].books
        #expect(books[0].managementNumber == "は001")  // 管理番号ありが最初
        #expect(books[1].managementNumber == nil)  // 管理番号なしが最後
    }
    
    /// 管理番号複雑ソートテスト
    ///
    /// ひらがな順→数字順の複雑なソートが正しく動作することを確認します。
    @Test("管理番号複雑ソート")
    func sortedByManagementNumberComplexOrder() {
        // 1. Arrange - 準備
        let complexBooks = [
            Book(title: "本A", managementNumber: "か010", kanaGroup: .ka),
            Book(title: "本B", managementNumber: "か002", kanaGroup: .ka),
            Book(title: "本C", managementNumber: "あ001", kanaGroup: .ka),
            Book(title: "本D", managementNumber: "か001", kanaGroup: .ka),
            Book(title: "本E", managementNumber: nil, kanaGroup: .ka),
        ]
        let sections = BookSection.createSections(from: complexBooks)
        
        // 2. Act - 実行
        let sortedSections = BookSection.sorted(sections: sections, by: .managementNumber)
        
        // 3. Assert - 検証
        #expect(sortedSections.count == 1)
        let books = sortedSections[0].books
        
        // ひらがな順、その中で数字順
        #expect(books[0].managementNumber == "あ001")
        #expect(books[1].managementNumber == "か001")
        #expect(books[2].managementNumber == "か002")
        #expect(books[3].managementNumber == "か010")
        #expect(books[4].managementNumber == nil)  // 管理番号なしは最後
    }
    
    /// 全角数字を含む管理番号ソートテスト
    ///
    /// 全角数字の管理番号が正しくソートされることを確認します。
    @Test("全角数字を含む管理番号ソート")
    func sortedByFullWidthNumbers() {
        // 1. Arrange - 準備（全角数字を含む管理番号）
        let fullWidthBooks = [
            Book(title: "本A", managementNumber: "あ０１０", kanaGroup: .a),  // 全角010
            Book(title: "本B", managementNumber: "あ００２", kanaGroup: .a),  // 全角002
            Book(title: "本C", managementNumber: "あ001", kanaGroup: .a),  // 半角001
            Book(title: "本D", managementNumber: "あ１００", kanaGroup: .a),  // 全角100
        ]
        let sections = BookSection.createSections(from: fullWidthBooks)
        
        // 2. Act - 実行
        let sortedSections = BookSection.sorted(sections: sections, by: .managementNumber)
        
        // 3. Assert - 検証
        #expect(sortedSections.count == 1)
        let books = sortedSections[0].books
        
        // 数字順（全角も半角も同等に扱われる）
        #expect(books[0].managementNumber == "あ001")  // 1
        #expect(books[1].managementNumber == "あ００２")  // 2
        #expect(books[2].managementNumber == "あ０１０")  // 10
        #expect(books[3].managementNumber == "あ１００")  // 100
    }
    
    /// 混在した全角・半角数字のソートテスト
    ///
    /// 同じグループ内で全角・半角が混在した場合のソートを確認します。
    @Test("混在した全角・半角数字のソート")
    func sortedByMixedWidthNumbers() {
        // 1. Arrange - 準備
        let mixedBooks = [
            Book(title: "本A", managementNumber: "さ００５", kanaGroup: .sa),  // 全角005
            Book(title: "本B", managementNumber: "さ003", kanaGroup: .sa),  // 半角003
            Book(title: "本C", managementNumber: "あ０２０", kanaGroup: .sa),  // 全角020（あ）
            Book(title: "本D", managementNumber: "さ010", kanaGroup: .sa),  // 半角010
        ]
        let sections = BookSection.createSections(from: mixedBooks)
        
        // 2. Act - 実行
        let sortedSections = BookSection.sorted(sections: sections, by: .managementNumber)
        
        // 3. Assert - 検証
        #expect(sortedSections.count == 1)
        let books = sortedSections[0].books
        
        // ひらがな順 → 数字順
        #expect(books[0].managementNumber == "あ０２０")  // あ020
        #expect(books[1].managementNumber == "さ003")  // さ003
        #expect(books[2].managementNumber == "さ００５")  // さ005
        #expect(books[3].managementNumber == "さ010")  // さ010
    }
    
    // MARK: - Integration Tests
    
    /// 全機能統合テスト
    ///
    /// セクション作成→フィルタリング→ソートの一連の流れが正しく動作することを確認します。
    @Test("全機能統合テスト")
    func fullWorkflow() {
        // 1. Arrange - 準備
        let sections = BookSection.createSections(from: testBooks)
        
        // 2. Act - 実行（"か"で検索、か行フィルター、管理番号順ソート）
        let filteredSections = BookSection.filtered(
            sections: sections,
            searchText: "か",
            selectedKanaFilter: .ka
        )
        let sortedSections = BookSection.sorted(sections: filteredSections, by: .managementNumber)
        
        // 3. Assert - 検証
        #expect(sortedSections.count == 1)
        #expect(sortedSections[0].books.count == 1)
        #expect(sortedSections[0].books[0].title == "かきくけこ")
        #expect(sortedSections[0].books[0].managementNumber == "か010")
    }
}
