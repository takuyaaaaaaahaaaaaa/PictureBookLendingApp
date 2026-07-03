import Foundation
import PictureBookLendingDomain

extension Loan {
    /// 返却期限の表示文字列（例：「6月20日(土)」）
    ///
    /// 家庭の枠など主動線での表示用。年は省略し、月日と曜日のみを日本語で表示する。
    var dueDateText: String {
        dueDate.formatted(
            .dateTime
                .month()
                .day()
                .weekday()
                .locale(Locale(identifier: "ja_JP"))
        )
    }
}
