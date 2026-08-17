/// 図書削除の確認ダイアログ文言
///
/// 削除の波及範囲（貸出中の図書の自動返却）を実行前に提示するための文言を組み立てます。
/// 削除は元に戻せないため、何が起きるかを漏れなく伝えることを優先します。
/// 利用者削除の [UserDeletionMessage] と対になる文言です。
enum BookDeletionMessage {
    /// 削除に伴って自動返却される貸出1件分
    struct AutoReturningLoan: Equatable {
        /// 貸出中の図書のタイトル
        let bookTitle: String
        /// 借りている利用者の名前
        let userName: String
    }
    
    /// 確認ダイアログの本文を組み立てる
    ///
    /// - Parameters:
    ///   - targetTitles: 削除を指示された図書のタイトル（空の場合は呼び出し側で削除自体を中止する想定）
    ///   - autoReturningLoans: 削除に伴って自動返却される貸出
    /// - Returns: 確認ダイアログに表示する本文
    static func make(
        targetTitles: [String],
        autoReturningLoans: [AutoReturningLoan]
    ) -> String {
        var lines = ["\(titlesInBrackets(targetTitles))を削除しますか？"]
        
        if !autoReturningLoans.isEmpty {
            lines.append("")
            lines.append("貸出中の図書が\(autoReturningLoans.count)冊あります。削除すると自動的に返却されます。")
            lines.append(
                contentsOf: autoReturningLoans.map { "・『\($0.bookTitle)』（\($0.userName)さん）" })
        }
        
        return lines.joined(separator: "\n")
    }
    
    /// タイトルを二重かぎ括弧付きで読点区切りに整形する
    private static func titlesInBrackets(_ titles: [String]) -> String {
        titles.map { "『\($0)』" }.joined(separator: "、")
    }
}
