import Foundation
import Kingfisher

/// 旧デフォルトキャッシュとは分け、既存ファイルを削除せず新しい期限を適用する。
enum ExternalBookCoverCache {
    private static let cache = ImageCache(name: "ExternalBookCovers-30Days-v1")

    @MainActor
    static func image(for url: URL?) -> KFImage {
        let image = KFImage(url)
        guard let scheme = url?.scheme?.lowercased(), scheme == "https" || scheme == "http" else {
            return image
        }
        let cachedImage =
            image
            .targetCache(cache)
            .memoryCacheExpiration(.expired)
            .diskCacheExpiration(.days(30))
            .diskCacheAccessExtending(.none)
        return cachedImage
    }
}
