import PictureBookLendingDomain
import PictureBookLendingInfrastructure

extension Book {
    /// 表示用の画像URLを取得する（ローカル画像優先）
    /// ローカル保存画像が存在する場合はそのファイルURLを返し、そうでなければ外部URLのサムネイルを返す
    /// - Returns: 画像のURL（存在しない場合はnil）
    var resolvedImageSource: String? {
        if let localImageFileName {
            return ImageStorageUtility.imageURL(for: localImageFileName).absoluteString
        }
        return displayImageSource
    }
    
    /// 表示用の画像URLを取得する（ローカル画像優先、小さいサムネイル優先）
    /// ローカル保存画像が存在する場合はそのファイルURLを返し、そうでなければ外部URLのサムネイルを返す
    /// - Returns: 画像のURL（存在しない場合はnil）
    var resolvedSmallImageSource: String? {
        if let localImageFileName {
            return ImageStorageUtility.imageURL(for: localImageFileName).absoluteString
        }
        return displaySmallImageSource
    }
}
