import Observation
import PictureBookLendingDomain

/// 図書一覧の絞り込み状態（検索テキストと五十音フィルタ）を管理する共通State
///
/// 貸出タブ・図書管理の両方で使う。検索と五十音チップの二重絞り込みで
/// 一覧が意図せず空になる問題を避けるため、両者を排他制御する：
/// - 検索を始めた（空→非空）ら五十音フィルタを解除する
/// - 五十音チップを選んだら検索テキスト（デバウンス済みも含む）をクリアする
///
/// 状態調整のロジックをContainerに散らさずここへ寄せることで、単体テスト可能にする。
/// Viewへはこのプロパティを読むバインディングを渡し、書き込みは各メソッドを経由させる。
@Observable
class BookListFilterState {
    /// 検索テキスト（一覧の絞り込みに即時反映する）
    private(set) var searchText: String
    /// サジェスト候補算出用にデバウンスした検索テキスト
    private(set) var debouncedSearchText: String
    /// 選択中の五十音フィルタ（nilなら全件）
    private(set) var selectedKanaFilter: KanaGroup?
    
    init(
        searchText: String = "",
        debouncedSearchText: String = "",
        selectedKanaFilter: KanaGroup? = nil
    ) {
        self.searchText = searchText
        self.debouncedSearchText = debouncedSearchText
        self.selectedKanaFilter = selectedKanaFilter
    }
    
    /// 検索テキストを更新する（`.searchable`のバインディング経由で呼ぶ）
    ///
    /// 空→非空へ変わったとき（＝検索を始めたとき）は五十音フィルタを解除し、
    /// 検索と五十音の二重絞り込みを避ける
    func updateSearchText(_ newValue: String) {
        let wasEmpty = searchText.isEmpty
        searchText = newValue
        if wasEmpty && !newValue.isEmpty {
            selectedKanaFilter = nil
        }
    }
    
    /// デバウンス済みの検索テキストを更新する（デバウンスTask完了時に呼ぶ）
    func updateDebouncedSearchText(_ newValue: String) {
        debouncedSearchText = newValue
    }
    
    /// 五十音フィルタを設定する（チップのトグルでBookListViewから書き込むバインディング経由）
    ///
    /// フィルタを選んだ（非nilにした）ら、検索テキスト（デバウンス済みも含む）をクリアし、
    /// 古いサジェストや検索絞り込みが残らないようにする
    func setKanaFilter(_ newValue: KanaGroup?) {
        selectedKanaFilter = newValue
        if newValue != nil {
            searchText = ""
            debouncedSearchText = ""
        }
    }
    
    /// 絞り込みをすべて解除する（貸出完了後のリセット等で使う）
    func reset() {
        searchText = ""
        debouncedSearchText = ""
        selectedKanaFilter = nil
    }
}
