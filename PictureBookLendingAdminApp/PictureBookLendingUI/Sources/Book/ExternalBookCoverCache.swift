import Foundation
import Kingfisher

/// 旧デフォルトキャッシュとは分け、既存ファイルを削除せず新しい期限を適用する。
enum ExternalBookCoverCache {
    private static let cache = ImageCache(name: "ExternalBookCovers-30Days-v1")

    @MainActor
    static func image(
        for url: URL?,
        cache overrideCache: ImageCache? = nil,
        expiration: StorageExpiration = .days(30)
    ) -> KFImage {
        let image = KFImage(url)
        guard let scheme = url?.scheme?.lowercased(), scheme == "https" || scheme == "http" else {
            return image
        }
        let cachedImage =
            image
            .targetCache(overrideCache ?? cache)
            .memoryCacheExpiration(.expired)
            .diskCacheExpiration(expiration)
            .diskCacheAccessExtending(.none)
        return cachedImage
    }
}
