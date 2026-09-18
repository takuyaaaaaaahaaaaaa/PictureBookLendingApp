import PictureBookLendingInfrastructure
import SwiftUI

extension EnvironmentValues {
    /// 利用ログの記録先
    ///
    /// 既定は何もしない実装。Preview・テストではこの既定値のまま動かせる。
    /// アプリ本体はエントリーポイントで実装を注入する。
    @Entry var analytics: any AnalyticsService = NoopAnalyticsService()
}

extension AnalyticsService {
    /// 型安全なイベントをname/paramsへ変換して記録する
    ///
    /// ContainerViewはこちらだけを呼び、文字列のイベント名を直接書かない。
    func track(_ event: AnalyticsEvent) {
        track(name: event.name, params: event.params)
    }
}
