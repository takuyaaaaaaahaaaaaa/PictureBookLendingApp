import Foundation
import PictureBookLendingDomain

extension Book {
    /// 表示用の画像URLを取得する（App層でのローカル画像対応版）
    /// ローカル画像が存在する場合はfile://付きフルパスを返し、そうでなければDomain層のプロパティを使用
    /// - Returns: 画像のURL（存在しない場合はnil）
    var displayImageSourceWithLocal: String? {
        // ローカル画像が存在する場合は優先してfile://付きフルパスを返す
        if let localImageFileName = localImageFileName {
            let documentsURL = FileManager.default.urls(
                for: .documentDirectory, in: .userDomainMask
            ).first!
            let imageDirectoryURL = documentsURL.appendingPathComponent("BookImages")
            let fileURL = imageDirectoryURL.appendingPathComponent(localImageFileName)
            return fileURL.absoluteString
        }
        // Domain層の基本的な外部URL取得を使用
        return displayImageSource
    }
    
    /// 表示用の画像URLを取得する（小さいサムネイル優先、App層でのローカル画像対応版）
    /// ローカル画像が存在する場合はfile://付きフルパスを返し、そうでなければDomain層のプロパティを使用
    /// - Returns: 画像のURL（存在しない場合はnil）
    var displaySmallImageSourceWithLocal: String? {
        // ローカル画像が存在する場合は優先してfile://付きフルパスを返す
        if let localImageFileName = localImageFileName {
            let documentsURL = FileManager.default.urls(
                for: .documentDirectory, in: .userDomainMask
            ).first!
            let imageDirectoryURL = documentsURL.appendingPathComponent("BookImages")
            let fileURL = imageDirectoryURL.appendingPathComponent(localImageFileName)
            return fileURL.absoluteString
        }
        // Domain層の基本的な外部URL取得を使用
        return displaySmallImageSource
    }
}
