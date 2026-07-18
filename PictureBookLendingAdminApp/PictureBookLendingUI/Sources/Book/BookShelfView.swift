import SwiftUI

/// 棚表示（木の本棚デザイン）の木質パーツ群
///
/// 保育園の絵本コーナーの本棚をメタファーにした表示形式で使う、
/// 背景・棚板・棚札のピュアUIコンポーネント。
/// 木目はテクスチャ画像を使わずGradientとCanvasで軽量に描画する
/// （設計方針は docs/SCREEN_DESIGN.md「棚表示」を参照）。

/// 棚表示のレイアウト定数
enum ShelfLayout {
    /// 背景の板1枚分の幅（継ぎ目線の間隔）
    static let plankWidth: CGFloat = 96
    /// 棚板の上面（絵本が乗る面）の高さ
    static let boardTopHeight: CGFloat = 8
    /// 棚板の前板の高さ
    static let boardFrontHeight: CGFloat = 16
    /// 棚1段内の絵本同士の間隔
    static let bookSpacing: CGFloat = 18
    /// 絵本セル1つの幅
    static let cellWidth: CGFloat = 120
    /// 棚札と絵本の並びの間隔
    static let plateSpacing: CGFloat = 8
    /// 棚段同士の間隔
    static let sectionSpacing: CGFloat = 26
    /// 棚段の左右余白
    static let rowHorizontalPadding: CGFloat = 20
}

/// 棚表示の配色
///
/// ライトモードは明るいクリーム〜薄茶の木地（保育園の家具にある明るい木のイメージ）、
/// ダークモードは焦げ茶の木地。文字は木地とのコントラストを確保した濃茶／クリームを使う
struct ShelfWoodColors {
    /// 背景木地のグラデーション（上端）
    let backgroundTop: Color
    /// 背景木地のグラデーション（下端）
    let backgroundBottom: Color
    /// 背景の板の継ぎ目線
    let plankLine: Color
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

    /// ライトモード配色（明るいクリーム〜薄茶の木地×濃茶のパーツ）
    static let light = ShelfWoodColors(
        backgroundTop: Color(red: 0.886, green: 0.780, blue: 0.612),
        backgroundBottom: Color(red: 0.835, green: 0.710, blue: 0.514),
        plankLine: Color(red: 0.470, green: 0.310, blue: 0.140).opacity(0.13),
        boardTopLight: Color(red: 0.902, green: 0.753, blue: 0.541),
        boardTopDark: Color(red: 0.824, green: 0.655, blue: 0.424),
        boardFrontLight: Color(red: 0.745, green: 0.561, blue: 0.345),
        boardFrontDark: Color(red: 0.659, green: 0.486, blue: 0.275),
        plateBackground: Color(red: 0.420, green: 0.271, blue: 0.125),
        plateText: Color(red: 0.976, green: 0.929, blue: 0.839),
        boardShadow: Color(red: 0.470, green: 0.310, blue: 0.140).opacity(0.35)
    )

    /// ダークモード配色（焦げ茶の木地×クリームの文字）
    static let dark = ShelfWoodColors(
        backgroundTop: Color(red: 0.333, green: 0.224, blue: 0.118),
        backgroundBottom: Color(red: 0.275, green: 0.188, blue: 0.102),
        plankLine: Color.black.opacity(0.25),
        boardTopLight: Color(red: 0.478, green: 0.333, blue: 0.188),
        boardTopDark: Color(red: 0.420, green: 0.282, blue: 0.149),
        boardFrontLight: Color(red: 0.369, green: 0.247, blue: 0.122),
        boardFrontDark: Color(red: 0.306, green: 0.204, blue: 0.094),
        plateBackground: Color(red: 0.184, green: 0.118, blue: 0.047),
        plateText: Color(red: 0.937, green: 0.851, blue: 0.706),
        boardShadow: Color.black.opacity(0.45)
    )

    /// カラースキームに応じた配色を返す
    static func colors(for colorScheme: ColorScheme) -> ShelfWoodColors {
        colorScheme == .dark ? .dark : .light
    }
}

/// 棚表示の背景（木地＋板の継ぎ目線）
///
/// 継ぎ目線は静的な描画のためCanvasで軽量に引く
struct ShelfWoodBackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let colors = ShelfWoodColors.colors(for: colorScheme)

        LinearGradient(
            colors: [colors.backgroundTop, colors.backgroundBottom],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay {
            Canvas { context, size in
                var x = ShelfLayout.plankWidth
                while x < size.width {
                    context.fill(
                        Path(CGRect(x: x, y: 0, width: 1, height: size.height)),
                        with: .color(colors.plankLine)
                    )
                    x += ShelfLayout.plankWidth
                }
            }
        }
    }
}

/// 棚板（絵本が乗る上面＋手前に見える前板の2面構成）
struct ShelfBoardView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let colors = ShelfWoodColors.colors(for: colorScheme)

        VStack(spacing: 0) {
            LinearGradient(
                colors: [colors.boardTopLight, colors.boardTopDark],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: ShelfLayout.boardTopHeight)

            LinearGradient(
                colors: [colors.boardFrontLight, colors.boardFrontDark],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: ShelfLayout.boardFrontHeight)
        }
        .compositingGroup()
        .shadow(color: colors.boardShadow, radius: 6, y: 5)
    }
}

/// 棚札（かなグループ名を表示する木の札）
struct KanaShelfPlateView: View {
    @Environment(\.colorScheme) private var colorScheme

    let text: String

    var body: some View {
        let colors = ShelfWoodColors.colors(for: colorScheme)

        Text(text)
            .font(.subheadline.bold())
            .foregroundStyle(colors.plateText)
            .padding(.horizontal, 14)
            .padding(.vertical, 3)
            .background(colors.plateBackground, in: RoundedRectangle(cornerRadius: 6))
    }
}

#Preview("棚パーツ") {
    VStack(alignment: .leading, spacing: ShelfLayout.sectionSpacing) {
        KanaShelfPlateView(text: "あ")
            .padding(.leading, ShelfLayout.rowHorizontalPadding)
        ShelfBoardView()
        KanaShelfPlateView(text: "か")
            .padding(.leading, ShelfLayout.rowHorizontalPadding)
        ShelfBoardView()
    }
    .padding(.vertical, 40)
    .background { ShelfWoodBackgroundView() }
}
