import SwiftUI

/// キオスク利用時の無操作タイムアウトを適用するViewModifier
///
/// 家庭の情報を次の利用者に見せないため、操作がないまま一定時間が経過したら
/// 置き去りとみなして呼び出し元が指定した復帰処理を行う（返却タブの家庭の画面・
/// 貸出フローのシート内画面で共通）。
/// 操作のたびに`ticket`が変わり、タスクが再起動して待ち時間が延長される。
/// 画面を離れるとタスクは自動キャンセルされる
private struct KioskIdleTimeoutModifier: ViewModifier {
    /// 無操作タイムアウトの秒数
    static let timeout: Duration = .seconds(15)
    
    /// 操作のたびに変える値（変わるたびにタイマーが再起動する）
    let ticket: Int
    /// タイムアウト時の処理（置き去り復帰等）
    let onTimeout: () -> Void
    
    func body(content: Content) -> some View {
        content.task(id: ticket) {
            try? await Task.sleep(for: Self.timeout)
            if Task.isCancelled { return }
            onTimeout()
        }
    }
}

extension View {
    /// キオスク利用時の無操作タイムアウトを適用する
    ///
    /// - Parameters:
    ///   - ticket: 操作のたびに変えるトークン
    ///   - onTimeout: タイムアウト時の処理
    func kioskIdleTimeout(ticket: Int, onTimeout: @escaping () -> Void) -> some View {
        modifier(KioskIdleTimeoutModifier(ticket: ticket, onTimeout: onTimeout))
    }
}
