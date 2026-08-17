/// 利用者削除の確認ダイアログ文言
///
/// 削除の波及範囲（関連する保護者のカスケード削除・借りたままの図書の自動返却）を
/// 実行前に提示するための文言を組み立てます。
/// 削除は元に戻せないため、何が起きるかを漏れなく伝えることを優先します。
enum UserDeletionMessage {
    /// 削除に伴って自動返却される貸出1件分
    struct AutoReturningLoan: Equatable {
        /// 借りている利用者の名前
        let userName: String
        /// 借りたままの図書のタイトル
        let bookTitle: String
    }
    
    /// 確認ダイアログの本文を組み立てる
    ///
    /// - Parameters:
    ///   - targetNames: 削除を指示された利用者の名前（空の場合は呼び出し側で削除自体を中止する想定）
    ///   - cascadedGuardianNames: 上記に連動して削除される保護者の名前
    ///   - autoReturningLoans: 削除に伴って自動返却される貸出
    /// - Returns: 確認ダイアログに表示する本文
    static func make(
        targetNames: [String],
        cascadedGuardianNames: [String],
        autoReturningLoans: [AutoReturningLoan]
    ) -> String {
        var lines = ["\(namesWithHonorific(targetNames))を削除しますか？"]
        
        if !cascadedGuardianNames.isEmpty {
            lines.append(
                "関連する保護者（\(namesWithHonorific(cascadedGuardianNames))）も合わせて削除されます。")
        }
        
        if !autoReturningLoans.isEmpty {
            lines.append("")
            lines.append("借りたままの図書が\(autoReturningLoans.count)冊あります。削除すると自動的に返却されます。")
            lines.append(
                contentsOf: autoReturningLoans.map { "・\($0.userName)さん『\($0.bookTitle)』" })
        }
        
        return lines.joined(separator: "\n")
    }
    
    /// 名前を敬称付きで読点区切りに整形する
    private static func namesWithHonorific(_ names: [String]) -> String {
        names.map { "\($0)さん" }.joined(separator: "、")
    }
}
