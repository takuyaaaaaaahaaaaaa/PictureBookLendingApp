import PictureBookLendingDomain
import Testing

@testable import PictureBookLendingAdmin

/// BookListFilterStateテストケース
///
/// 検索テキストと五十音フィルタの排他制御を検証する：
/// - 検索を始めた（空→非空）ら五十音フィルタが解除される
/// - 五十音チップを選んだら検索テキストがクリアされる
/// - reset()ですべての絞り込みが解除される
@Suite("BookListFilterState Tests")
struct BookListFilterStateTests {
    
    // MARK: - 検索テキスト更新時の排他制御
    
    /// 検索を始める（空→非空）と五十音フィルタが解除される
    @Test("検索開始で五十音フィルタが解除される")
    func startingSearchClearsKanaFilter() {
        // 1. Arrange - かなフィルタが選択されている状態
        let state = BookListFilterState(selectedKanaFilter: .ka)
        
        // 2. Act - 検索テキストを入力する
        state.updateSearchText("あ")
        
        // 3. Assert
        #expect(state.searchText == "あ")
        #expect(state.selectedKanaFilter == nil)
    }
    
    /// 既に検索中（非空→非空）の入力更新では五十音フィルタに触れない
    /// （そもそも検索中はフィルタは解除済みだが、更新のたびにnil代入で
    ///  無用な変更通知を出さないことを担保する）
    @Test("検索中の入力更新は排他制御を再発火しない")
    func updatingWhileSearchingDoesNotReclear() {
        // 1. Arrange - 既に検索中でフィルタは解除済み
        let state = BookListFilterState(searchText: "あ")
        
        // 2. Act - さらに文字を追加する
        state.updateSearchText("あい")
        
        // 3. Assert - 検索テキストは更新され、フィルタはnilのまま
        #expect(state.searchText == "あい")
        #expect(state.selectedKanaFilter == nil)
    }
    
    /// 検索テキストを空にクリアしても、その操作自体はフィルタを触らない
    @Test("検索テキストのクリアはフィルタに影響しない")
    func clearingSearchTextDoesNotTouchFilter() {
        // 1. Arrange - 検索中
        let state = BookListFilterState(searchText: "あ")
        
        // 2. Act - 検索テキストを空にする
        state.updateSearchText("")
        
        // 3. Assert
        #expect(state.searchText == "")
        #expect(state.selectedKanaFilter == nil)
    }
    
    // MARK: - 五十音フィルタ設定時の排他制御
    
    /// 五十音チップを選ぶと検索テキストがクリアされる
    @Test("五十音フィルタ選択で検索テキストがクリアされる")
    func selectingKanaFilterClearsSearchText() {
        // 1. Arrange - 検索中
        let state = BookListFilterState(searchText: "あ")
        
        // 2. Act - 五十音チップを選ぶ
        state.setKanaFilter(.ka)
        
        // 3. Assert
        #expect(state.selectedKanaFilter == .ka)
        #expect(state.searchText == "")
    }
    
    /// 五十音フィルタを解除（nil設定）しても検索テキストはクリアしない
    @Test("五十音フィルタ解除は検索テキストをクリアしない")
    func deselectingKanaFilterKeepsSearchText() {
        // 1. Arrange - かなフィルタ選択中（このとき検索は空のはずだが、
        //   解除がクリアを引き起こさないことを、あえて検索テキストを入れて確認する）
        let state = BookListFilterState(searchText: "既存", selectedKanaFilter: .ka)
        
        // 2. Act - フィルタを解除する
        state.setKanaFilter(nil)
        
        // 3. Assert
        #expect(state.selectedKanaFilter == nil)
        #expect(state.searchText == "既存")
    }
    
    // MARK: - reset
    
    /// reset()ですべての絞り込みが解除される
    @Test("resetですべての絞り込みが解除される")
    func resetClearsEverything() {
        // 1. Arrange - 検索とフィルタ両方に値が入っている状態
        let state = BookListFilterState(
            searchText: "あ",
            selectedKanaFilter: .ka)
        
        // 2. Act
        state.reset()
        
        // 3. Assert
        #expect(state.searchText == "")
        #expect(state.selectedKanaFilter == nil)
    }
}
