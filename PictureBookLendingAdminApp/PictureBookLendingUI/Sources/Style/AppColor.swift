import SwiftUI

/// 操作と状態を区別する共通色。木地は棚専用のShelfWoodColorsに委ねる。
/// 状態を示すときは、色だけでなく文字とSF Symbolを併記する。
public enum AppColor: Hashable {
    /// 本体／WidgetのAccentColorを参照する。UIパッケージでは再定義しない。
    public static let accent = Color.accentColor
    /// 壁紙・革の背景に載る主要な見出しと名前。
    public static let libraryTitle = Color("LibraryTitle", bundle: .module)
    /// 同じ背景に載る著者名や補足情報。
    public static let librarySecondaryText = Color("LibrarySecondaryText", bundle: .module)
    /// 表示切り替えと返却操作に使う、明暗両方で目立つ暖色。
    public static let libraryAction = Color("LibraryAction", bundle: .module)
    /// 返却カードの輪郭に使う控えめな金茶。
    public static let returnCardBorder = Color("ReturnCardBorder", bundle: .module)
    /// 貸出可能な本の「借りる」操作。状態色の緑とは別にコントラストを確保する。
    public static let borrowAction = Color("BorrowAction", bundle: .module)
    /// 借りる操作の文字。ライトは白、ダークは深緑に合わせた淡い真鍮色。
    public static let borrowActionForeground = Color("BorrowActionForeground", bundle: .module)
    /// 貸出中の文字・アイコン。淡い状態面との組で使う。
    public static let lentForeground = Color("Lent", bundle: .module)
    public static let lentSurface = Color("LentSurface", bundle: .module)
    public static let lent = lentForeground
    public static let available = Color("Available", bundle: .module)
    public static let overdue = Color("Overdue", bundle: .module)
    public static let returned = Color("Returned", bundle: .module)
    public static let destructive = Color("Destructive", bundle: .module)
    public static let cardSurface = Color("CardSurface", bundle: .module)
    /// 貸出・返却の利用者選択で、壁紙／革から独立して見える図書カードの紙面。
    public static let borrowerCardSurface = Color("BorrowerCardSurface", bundle: .module)
    public static let chipSurface = Color("ChipSurface", bundle: .module)
    /// アクセント／状態色を不透明に塗った面の文字色。暗色モードは濃い文字にする。
    public static let onEmphasis = Color("OnEmphasis", bundle: .module)
}
