import SwiftUI

/// 操作と状態を区別する共通色。木地は棚専用のShelfWoodColorsに委ねる。
/// 状態を示すときは、色だけでなく文字とSF Symbolを併記する。
public enum AppColor: Hashable {
    /// 本体／WidgetのAccentColorを参照する。UIパッケージでは再定義しない。
    public static let accent = Color.accentColor
    /// 貸出中の文字・アイコン。淡い状態面との組で使う。
    public static let lentForeground = Color("Lent", bundle: .module)
    public static let lentSurface = Color("LentSurface", bundle: .module)
    public static let lent = lentForeground
    public static let available = Color("Available", bundle: .module)
    public static let overdue = Color("Overdue", bundle: .module)
    public static let returned = Color("Returned", bundle: .module)
    public static let destructive = Color("Destructive", bundle: .module)
    public static let cardSurface = Color("CardSurface", bundle: .module)
    public static let chipSurface = Color("ChipSurface", bundle: .module)
    /// アクセント／状態色を不透明に塗った面の文字色。暗色モードは濃い文字にする。
    public static let onEmphasis = Color("OnEmphasis", bundle: .module)
}
