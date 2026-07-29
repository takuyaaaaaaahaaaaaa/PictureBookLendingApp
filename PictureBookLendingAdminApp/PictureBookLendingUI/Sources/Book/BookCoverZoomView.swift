import SwiftUI

/// 表紙の拡大表示View（フルスクリーン提示用のピュアUI）
///
/// 文字が見えづらい利用者が図書のタイトル等を確かめられるよう、
/// 表紙を画面いっぱいに表示する。画面のどこをタップしても閉じられる。
/// ✕ボタンは、タップで閉じる作法を知らない利用者のための明示的な閉じる手段
/// （貸出シートの✕と同じ作法）
public struct BookCoverZoomView: View {
    /// 表示する表紙画像のURL（App層で解決済み・大きいサムネイル優先）
    let imageURL: String?
    /// 大きい画像の読み込み中に表示する小サムネイルのURL（低解像度→高解像度の段階表示用）。
    /// ズーム遷移の瞬間にプレースホルダーアイコンへ退行して
    /// 「同じものが大きくなった」という連続性が崩れるのを防ぐ
    let placeholderImageURL: String?
    /// 図書のタイトル（VoiceOver用。拡大画面の目的がタイトル確認のため必須）
    let title: String
    /// 閉じる要求（タップ・✕ボタン共通）
    let onClose: () -> Void
    
    public init(
        imageURL: String?,
        placeholderImageURL: String? = nil,
        title: String,
        onClose: @escaping () -> Void
    ) {
        self.imageURL = imageURL
        self.placeholderImageURL = placeholderImageURL
        self.title = title
        self.onClose = onClose
    }
    
    private enum Layout {
        /// 画像が無い図書のプレースホルダーアイコンのサイズ
        static let placeholderIconSize: CGFloat = 96
        /// 表紙と画面端の間隔（閉じるためのタップ余白を兼ねる）
        static let imagePadding: CGFloat = 24
    }
    
    public var body: some View {
        // 表紙に集中できるよう背景は黒一色（写真アプリの拡大表示と同じ作法）
        Color.black
            .ignoresSafeArea()
            .overlay {
                BookImageView(imageURL: imageURL) {
                    if let placeholderImageURL {
                        BookImageView(imageURL: placeholderImageURL) {
                            placeholderIcon
                        }
                    } else {
                        placeholderIcon
                    }
                }
                .aspectRatio(contentMode: .fit)
                .padding(Layout.imagePadding)
                .accessibilityLabel("『\(title)』の表紙")
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onClose)
            .overlay(alignment: .topTrailing) {
                closeButton
            }
    }
    
    private var placeholderIcon: some View {
        Image(systemName: "book.closed")
            .foregroundStyle(.secondary)
            .font(.system(size: Layout.placeholderIconSize))
    }
    
    private var closeButton: some View {
        Button(action: onClose) {
            Image(systemName: "xmark.circle.fill")
                .font(.largeTitle)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.white)
        }
        .padding()
        .accessibilityLabel("閉じる")
    }
}

#Preview {
    // 画像が無い場合のプレースホルダー表示（実画像はURLが必要なため）
    BookCoverZoomView(imageURL: nil, title: "ぐりとぐら", onClose: {})
}
