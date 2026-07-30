import PictureBookLendingInfrastructure

/// 利用ログのイベント語彙（docs/ANALYTICS_DESIGN.md §3 のv1・10イベント）
///
/// `find_method: shelf` のような語彙は画面の関心事でありドメイン概念ではないため、
/// Domain層ではなくApp層のPresentation配下に置く（`+Formatter`と同じ役回り）。
/// 記録するのは所要時間・件数・列挙値だけで、利用者ID・図書ID・検索文字列は載せない
/// （大原則2）。イベントを増やすときは、まず設計書に問いを追記してからここへ1ケース足す。
enum AnalyticsEvent {
    /// 図書の見つけ方（貸出フロー開始時）
    enum BookFindMethod: String {
        /// 検索で見つけた
        case search
        /// 五十音チップで絞り込んで見つけた
        case kanaIndex = "kana_index"
        /// 棚表示で見つけた
        case shelf
        /// 一覧をスクロールして見つけた
        case scroll
    }
    
    /// 貸出フローで最後に居た画面（離脱地点の特定用）
    enum BorrowLastStep: String {
        /// 「だれが借りますか？」（利用者選択）
        case userSelection = "user_selection"
        /// 「どの枠で借りますか？」（家庭の枠確認）
        case slotSelection = "slot_selection"
    }
    
    /// 貸出フローを離脱した理由
    enum AbandonReason: String {
        /// ✕ボタンで自分で閉じた
        case userClosed = "user_closed"
        /// 無操作タイムアウトの置き去り復帰で閉じた
        case idleTimeout = "idle_timeout"
    }
    
    /// 貸出に使った枠の種別
    enum SlotType: String {
        /// 園児の枠
        case child
        /// 保護者の枠
        case guardian
    }
    
    /// 返却フローで家庭を見つけた方法
    enum ReturnFindMethod: String {
        /// 名前の検索でヒットした
        case searchName = "search_name"
        /// 図書のタイトルの検索でヒットした
        case searchBookTitle = "search_book_title"
        /// 検索せず一覧から選んだ（組チップ・スクロールを含む）
        case browse
    }
    
    /// 取り消しが行われたフロー
    enum UndoFlow: String {
        /// 貸出フロー内での返却取り消し（枠の入れ替え）
        case borrow
        /// 返却フローでの返却取り消し
        case returning = "return"
    }
    
    /// 図書一覧で図書をタップし貸出シートが開いた
    case borrowFlowStarted(findMethod: BookFindMethod)
    /// 名前一覧で名前をタップした
    case borrowUserSelected(elapsedMs: Int?)
    /// 枠タップで貸出が確定した
    case borrowCompleted(totalMs: Int?, slotType: SlotType, guardianFallback: Bool)
    /// 貸出シートが完了せず閉じた
    case borrowAbandoned(lastStep: BorrowLastStep, reason: AbandonReason, elapsedMs: Int?)
    /// 家庭の画面に到達したが空き枠がなかった
    case borrowBlockedNoSlot
    /// 図書検索の入力が確定した（デバウンス後）
    case bookSearchPerformed(
        queryLength: Int, resultCount: Int, fuzzyTriggered: Bool, zeroHit: Bool)
    /// 名前一覧から家庭の画面を開いた
    case returnFamilyOpened(findMethod: ReturnFindMethod, overdueFilterActive: Bool)
    /// 返却が確定した
    case returnCompleted(elapsedMs: Int?, wasOverdue: Bool)
    /// Undoカードで取り消した
    case undoPerformed(flow: UndoFlow)
    /// 返却タブ「延滞のみ」フィルタをONにした
    case overdueFilterToggled
    
    /// イベント名（GA4流のsnake_case）
    var name: String {
        switch self {
        case .borrowFlowStarted: "borrow_flow_started"
        case .borrowUserSelected: "borrow_user_selected"
        case .borrowCompleted: "borrow_completed"
        case .borrowAbandoned: "borrow_abandoned"
        case .borrowBlockedNoSlot: "borrow_blocked_no_slot"
        case .bookSearchPerformed: "book_search_performed"
        case .returnFamilyOpened: "return_family_opened"
        case .returnCompleted: "return_completed"
        case .undoPerformed: "undo_performed"
        case .overdueFilterToggled: "overdue_filter_toggled"
        }
    }
    
    /// イベントのプロパティ
    ///
    /// 所要時間は計測が無効化されている（バックグラウンド滞在）ことがあり、
    /// その場合はキーごと落とす。0や-1のような番兵を送って集計を汚さない。
    var params: [String: AnalyticsParamValue] {
        switch self {
        case .borrowFlowStarted(let findMethod):
            ["find_method": .string(findMethod.rawValue)]
        case .borrowUserSelected(let elapsedMs):
            Self.duration("elapsed_ms", elapsedMs)
        case .borrowCompleted(let totalMs, let slotType, let guardianFallback):
            [
                "slot_type": .string(slotType.rawValue),
                "guardian_fallback": .bool(guardianFallback),
            ].merging(Self.duration("total_ms", totalMs)) { current, _ in current }
        case .borrowAbandoned(let lastStep, let reason, let elapsedMs):
            [
                "last_step": .string(lastStep.rawValue),
                "reason": .string(reason.rawValue),
            ].merging(Self.duration("elapsed_ms", elapsedMs)) { current, _ in current }
        case .borrowBlockedNoSlot:
            [:]
        case .bookSearchPerformed(
            let queryLength, let resultCount, let fuzzyTriggered, let zeroHit):
            [
                "query_length": .int(queryLength),
                "result_count": .int(resultCount),
                "fuzzy_triggered": .bool(fuzzyTriggered),
                "zero_hit": .bool(zeroHit),
            ]
        case .returnFamilyOpened(let findMethod, let overdueFilterActive):
            [
                "find_method": .string(findMethod.rawValue),
                "overdue_filter_active": .bool(overdueFilterActive),
            ]
        case .returnCompleted(let elapsedMs, let wasOverdue):
            ["was_overdue": .bool(wasOverdue)]
                .merging(Self.duration("elapsed_ms", elapsedMs)) { current, _ in current }
        case .undoPerformed(let flow):
            ["flow": .string(flow.rawValue)]
        case .overdueFilterToggled:
            [:]
        }
    }
    
    /// 所要時間のプロパティ（計測できていなければ空＝キーを含めない）
    private static func duration(_ key: String, _ milliseconds: Int?)
        -> [String: AnalyticsParamValue]
    {
        if let milliseconds {
            [key: .int(milliseconds)]
        } else {
            [:]
        }
    }
}
