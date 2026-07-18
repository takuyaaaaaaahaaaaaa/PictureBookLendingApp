import PictureBookLendingDomain

extension LoanMilestone {
    /// お祝いカードのタイトル（例：「10回よんだよ！」）
    ///
    /// 主役は園児。お迎えの場で本人・保護者・先生が一緒に見るため、
    /// 数字が主役になる短い言葉にする
    var celebrationTitle: String {
        switch self {
        case .repeatedBook(let count): "\(count)回よんだよ！"
        case .consecutiveWeeks(let count): "\(count)週連続！"
        case .distinctBooks(let count): "\(count)冊よんだよ！"
        }
    }

    /// お祝いカードのメッセージ（利用者名・図書タイトルを添える）
    func celebrationMessage(userName: String, bookTitle: String) -> String {
        switch self {
        case .repeatedBook(let count):
            "\(userName)さん、『\(bookTitle)』を\(count)回かりました！だいすきな1冊だね"
        case .consecutiveWeeks(let count):
            "\(userName)さん、\(count)週つづけてかりています！すごい！"
        case .distinctBooks(let count):
            "\(userName)さん、これで\(count)冊目の図書です！おめでとう！"
        }
    }
}
