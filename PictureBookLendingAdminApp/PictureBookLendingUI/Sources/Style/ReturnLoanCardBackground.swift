import SwiftUI

/// カードに暗色では革、明色では紙の質感を薄く重ねる。
struct ReturnLoanCardBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    
    let cornerRadius: CGFloat
    let surface: Color
    let borderWidth: CGFloat
    
    /// 通知カードは背景との明度差を確保するため、明るい面色を指定する。
    init(
        cornerRadius: CGFloat,
        surface: Color = AppColor.cardSurface,
        borderWidth: CGFloat = 1
    ) {
        self.cornerRadius = cornerRadius
        self.surface = surface
        self.borderWidth = borderWidth
    }
    
    var body: some View {
        let isDark = colorScheme == .dark
        let shape = RoundedRectangle(cornerRadius: cornerRadius)
        
        shape
            .fill(surface)
            .overlay {
                GeometryReader { geometry in
                    Image(isDark ? "LeatherDark" : "WallpaperLight", bundle: .module)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .opacity(isDark ? 0.16 : 0.08)
                        .clipped()
                }
            }
            .clipShape(shape)
            .overlay {
                shape.strokeBorder(
                    AppColor.returnCardBorder,
                    lineWidth: colorSchemeContrast == .increased ? max(borderWidth, 2) : borderWidth
                )
            }
            .shadow(color: .black.opacity(isDark ? 0.28 : 0.10), radius: 12, y: 5)
    }
}
