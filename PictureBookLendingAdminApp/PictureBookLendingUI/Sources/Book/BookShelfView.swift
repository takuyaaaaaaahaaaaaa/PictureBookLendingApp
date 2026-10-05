import SwiftUI

/// 棚表示の棚板と棚札
///
/// 保育園の絵本コーナーの本棚をメタファーにした表示形式で使う、
/// 細い棚板・棚札のピュアUIコンポーネント。
/// 棚板はGradientと明暗それぞれの木目素材で描画する
/// （設計方針は docs/SCREEN_DESIGN.md「棚表示」を参照）。

/// 棚表示のレイアウト定数
///
/// 間隔は4ptグリッドに乗せ、「かなグループ間(56) > 棚段間(32) > 段内の要素間(24)」の
/// 3階層で差をつける。同じ階層の間隔は同じ値にそろえ、位置関係のリズムを保つ
enum ShelfLayout {
    /// 棚板の上面（絵本が乗る面）の高さ
    static let boardTopHeight: CGFloat = 4
    /// 棚板の前板の高さ
    static let boardFrontHeight: CGFloat = 11
    /// 棚1段内の絵本同士の間隔（グリッド表示のセル間隔と同値にそろえる）
    static let bookSpacing: CGFloat = 16
    /// 絵本の並び（セル下端の貸出ボタン等）と棚板の間隔（段内の要素間）
    static let boardSpacing: CGFloat = 24
    /// 同じかなグループ内で折り返した棚段同士の間隔
    static let rowSpacing: CGFloat = 32
    /// かなグループ同士の間隔
    /// （棚段間より明確に大きくし、棚板からぶら下がるかなラベルを収める余白を兼ねる）
    static let sectionSpacing: CGFloat = 56
    /// 棚板とぶら下がるかなラベルの間隔
    static let plateHangGap: CGFloat = 8
    /// 棚段の左右余白
    static let rowHorizontalPadding: CGFloat = 20
    /// 一覧コンテンツ全体の上下余白
    static let contentVerticalPadding: CGFloat = 24
}

/// 細い棚板と棚札の配色
///
/// ライトモードは明るい木、ダークモードは焦げ茶の木を使う
struct ShelfWoodColors {
    /// 棚板上面のグラデーション（上端）
    let boardTopLight: Color
    /// 棚板上面のグラデーション（下端）
    let boardTopDark: Color
    /// 棚板前板のグラデーション（上端）
    let boardFrontLight: Color
    /// 棚板前板のグラデーション（下端）
    let boardFrontDark: Color
    /// 棚札の背景
    let plateBackground: Color
    /// 棚札の文字
    let plateText: Color
    /// 棚板が落とす影
    let boardShadow: Color
    
    /// ライトモード配色（白い壁紙×明るい木）
    static let light = ShelfWoodColors(
        boardTopLight: Color(red: 0.914, green: 0.839, blue: 0.706),
        boardTopDark: Color(red: 0.847, green: 0.725, blue: 0.553),
        boardFrontLight: Color(red: 0.831, green: 0.678, blue: 0.471),
        boardFrontDark: Color(red: 0.745, green: 0.561, blue: 0.345),
        plateBackground: Color(red: 0.992, green: 0.973, blue: 0.929),
        plateText: Color(red: 0.302, green: 0.196, blue: 0.094),
        boardShadow: Color(red: 0.470, green: 0.310, blue: 0.140).opacity(0.25)
    )
    
    /// ダークモード配色（黒革×焦げ茶の棚板）
    static let dark = ShelfWoodColors(
        boardTopLight: Color(red: 0.541, green: 0.384, blue: 0.251),
        boardTopDark: Color(red: 0.459, green: 0.314, blue: 0.184),
        boardFrontLight: Color(red: 0.404, green: 0.263, blue: 0.153),
        boardFrontDark: Color(red: 0.314, green: 0.204, blue: 0.114),
        plateBackground: Color(red: 0.929, green: 0.882, blue: 0.796),
        plateText: Color(red: 0.216, green: 0.137, blue: 0.063),
        boardShadow: Color.black.opacity(0.48)
    )
    
    /// カラースキームに応じた配色を返す
    static func colors(for colorScheme: ColorScheme) -> ShelfWoodColors {
        colorScheme == .dark ? .dark : .light
    }
}

/// 棚板（絵本が乗る上面＋手前に見える前板の2面構成）
///
/// `hangingLabelText` を渡すと、棚板の下にかなラベルをぶら下げる。
/// 「棚板の下にぶら下がっている札は、その下に並ぶ絵本の見出し」という
/// 一貫したルールで読めるようにする（最上段の横木にも同じルールを適用できる）
struct ShelfBoardView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var hangingLabelText: String? = nil
    
    var body: some View {
        let isDark = colorScheme == .dark
        let colors = ShelfWoodColors.colors(for: colorScheme)
        
        VStack(spacing: 0) {
            LinearGradient(
                colors: [colors.boardTopLight, colors.boardTopDark],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: ShelfLayout.boardTopHeight)
            .overlay(alignment: .top) {
                Color.white.opacity(isDark ? 0.24 : 0.42)
                    .frame(height: 1)
            }
            
            LinearGradient(
                colors: [colors.boardFrontLight, colors.boardFrontDark],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: ShelfLayout.boardFrontHeight)
            .overlay {
                GeometryReader { geometry in
                    Image(isDark ? "DarkWalnut" : "LightOak", bundle: .module)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .opacity(isDark ? 0.55 : 0.48)
                        .clipped()
                }
            }
            .overlay(alignment: .bottom) {
                Color.black.opacity(isDark ? 0.42 : 0.16)
                    .frame(height: 1)
            }
            .clipped()
        }
        .compositingGroup()
        .shadow(color: colors.boardShadow, radius: 5, y: 4)
        .overlay(alignment: .bottomLeading) {
            if let hangingLabelText {
                KanaShelfPlateView(text: hangingLabelText)
                    .padding(.leading, ShelfLayout.rowHorizontalPadding)
                    .alignmentGuide(.bottom) { dimensions in
                        // ラベルのbottomガイドを自身のtopより上に設定することで、
                        // 棚板の下側へgapぶん離してぶら下げる
                        dimensions[.top] - ShelfLayout.plateHangGap
                    }
            }
        }
    }
}

/// 棚札（かなグループ名を表示する紙ラベル）
///
/// 棚板の前面に貼って使う。木の札だと木地と同系色で埋もれるため、
/// 「クリーム色の紙×濃茶の文字」でコントラストを確保する
struct KanaShelfPlateView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let text: String
    
    var body: some View {
        let colors = ShelfWoodColors.colors(for: colorScheme)
        
        Text(text)
            .font(.title3.bold())
            .foregroundStyle(colors.plateText)
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            .background(colors.plateBackground, in: RoundedRectangle(cornerRadius: 6))
            .shadow(color: colors.boardShadow.opacity(0.5), radius: 2, y: 1)
    }
}

#Preview("棚パーツ") {
    VStack(alignment: .leading, spacing: ShelfLayout.sectionSpacing) {
        ShelfBoardView(hangingLabelText: "あ")
        ShelfBoardView(hangingLabelText: "か")
        ShelfBoardView()
    }
    .padding(.vertical, 60)
    .background { LibrarySurfaceBackgroundView() }
}
