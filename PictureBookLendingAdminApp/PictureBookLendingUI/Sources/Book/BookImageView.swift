import Kingfisher
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
        KFImage(URL(string: imageURL ?? ""))
            .placeholder {
                placeholder
            }
            .resizable()
    }
    
}

#Preview {
    VStack {
        // ローカル画像のプレビューは実際のファイルが必要なので、プレースホルダーを表示
        BookImageView(imageURL: nil) {
            Image(systemName: "book.closed")
                .foregroundStyle(.secondary)
                .font(.system(size: 40))
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
