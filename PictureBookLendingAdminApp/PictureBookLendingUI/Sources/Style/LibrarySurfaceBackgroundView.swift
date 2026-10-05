import SwiftUI

/// 貸出・返却の一覧に使う壁紙／革の背景。質感画像は一覧の背面に1枚だけ描画する。
public struct LibrarySurfaceBackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    public init() {}
    
    public var body: some View {
        let isDark = colorScheme == .dark
        GeometryReader { geometry in
            Color(
                red: isDark ? 0.145 : 0.973,
                green: isDark ? 0.149 : 0.965,
                blue: isDark ? 0.149 : 0.945
            )
            .overlay {
                Image(isDark ? "LeatherDark" : "WallpaperLight", bundle: .module)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .opacity(isDark ? 0.11 : 0.18)
                    .clipped()
            }
        }
        .allowsHitTesting(false)
    }
}
