import SwiftUI

/// 絵本画像表示用のビュー
/// KFImageを使ってローカル画像とリモート画像の両方に対応
public struct BookImageView<PlaceholderContent: View>: View {
    let imageURL: String?
    let placeholder: PlaceholderContent

    public init(
        imageURL: String?,
        @ViewBuilder placeholder: () -> PlaceholderContent
    ) {
        self.imageURL = imageURL
        self.placeholder = placeholder()
    }

    public var body: some View {
        ExternalBookCoverCache.image(for: URL(string: imageURL ?? ""))
            .placeholder {
                placeholder
            }
            .resizable()
    }

}

/// 絵本一覧の画像未設定・読み込み中・読み込み失敗時に表示する表紙。
struct BookCoverPlaceholder: View {
    @Environment(\.colorScheme) private var colorScheme
    let font: Font
    let cornerRadius: CGFloat

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius)
        // ダークは親のマテリアルをそのまま使い、ライトだけ面と輪郭を補う。
        let isLight = colorScheme == .light
        Image(systemName: "book.closed")
            .foregroundStyle(.secondary)
            .font(font)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                shape.fill(isLight ? AppColor.chipSurface : .clear)
            }
            .overlay {
                shape.strokeBorder(
                    isLight ? AppColor.returnCardBorder : .clear,
                    lineWidth: 1
                )
            }
    }
}

#Preview {
    VStack {
        // ローカル画像のプレビューは実際のファイルが必要なので、プレースホルダーを表示
        BookImageView(imageURL: nil) {
            BookCoverPlaceholder(font: .system(size: 40), cornerRadius: 8)
        }
        .frame(width: 100, height: 130)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))

        Text("画像プレビュー")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .padding()
}
