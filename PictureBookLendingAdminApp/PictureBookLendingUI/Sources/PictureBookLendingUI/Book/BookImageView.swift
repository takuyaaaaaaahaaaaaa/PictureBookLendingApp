import Kingfisher
import PictureBookLendingDomain
import SwiftUI

#if canImport(UIKit)
    import UIKit
#endif

/// 絵本画像表示用のビュー
/// ローカル画像とリモート画像の両方に対応
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
        Group {
            if let imageURL = imageURL {
                if isLocalImagePath(imageURL) {
                    // ローカル画像の表示
                    #if canImport(UIKit)
                        if let localImage = loadLocalImage(from: imageURL) {
                            Image(uiImage: localImage)
                                .resizable()
                        } else {
                            placeholder
                        }
                    #else
                        placeholder
                    #endif
                } else {
                    // リモート画像の表示（従来のKingfisher）
                    KFImage(URL(string: imageURL))
                        .placeholder {
                            placeholder
                        }
                        .resizable()
                }
            } else {
                placeholder
            }
        }
    }
    
    /// ローカル画像パスかどうかを判定
    private func isLocalImagePath(_ path: String) -> Bool {
        guard let url = URL(string: path) else { return false }
        return url.scheme == "file"
    }
    
    /// ローカル画像を読み込む
    #if canImport(UIKit)
        private func loadLocalImage(from path: String) -> UIImage? {
            guard let url = URL(string: path) else { return nil }
            return UIImage(contentsOfFile: url.path)
        }
    #else
        private func loadLocalImage(from path: String) -> NSImage? {
            return nil
        }
    #endif
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
