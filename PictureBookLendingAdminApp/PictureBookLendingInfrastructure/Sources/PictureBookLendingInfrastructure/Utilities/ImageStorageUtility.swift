import Foundation

#if canImport(UIKit)
    import UIKit
#endif

/// 画像のローカル保存・読み込みを管理するユーティリティ
public enum ImageStorageUtility {
    
    #if canImport(UIKit)
        
        /// 画像保存用のディレクトリ名
        private static let imageDirectoryName = "BookImages"
        
        /// 画像保存用ディレクトリのURL
        private static var imageDirectoryURL: URL {
            let documentsURL = FileManager.default.urls(
                for: .documentDirectory, in: .userDomainMask
            ).first!
            return documentsURL.appendingPathComponent(imageDirectoryName)
        }
        
        /// 画像保存用ディレクトリを作成
        private static func createImageDirectoryIfNeeded() throws {
            let imageDirectory = imageDirectoryURL
            if !FileManager.default.fileExists(atPath: imageDirectory.path) {
                try FileManager.default.createDirectory(
                    at: imageDirectory,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            }
        }
        
        /// 画像を保存してファイル名を返す
        /// - Parameters:
        ///   - image: 保存する画像
        ///   - fileName: ファイル名（拡張子なし、デフォルトでUUID生成）
        /// - Returns: 保存されたファイル名（拡張子付き）
        /// - Throws: 保存に失敗した場合のエラー
        public static func saveImage(_ image: UIImage, fileName: String = UUID().uuidString) throws
            -> String
        {
            try createImageDirectoryIfNeeded()
            
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                throw ImageStorageError.imageCompressionFailed
            }
            
            let fullFileName = "\(fileName).jpg"
            let fileURL = imageDirectoryURL.appendingPathComponent(fullFileName)
            
            try imageData.write(to: fileURL)
            
            // ファイル名のみを返す（アップデート時のコンテナID変更に対応）
            return fullFileName
        }
        
        /// ローカルパスまたはファイル名から画像を読み込む
        /// - Parameter pathOrFileName: ローカルファイルパス（file://形式）またはファイル名
        /// - Returns: 読み込まれた画像（失敗時はnil）
        public static func loadImage(from pathOrFileName: String) -> UIImage? {
            // TODO: file://スキームの後方互換性サポート - 将来的に削除予定
            // file://スキームの場合は絶対パス（後方互換性のため）
            if pathOrFileName.hasPrefix("file://") {
                guard let url = URL(string: pathOrFileName) else { return nil }
                return UIImage(contentsOfFile: url.path)
            }
            
            // ファイル名のみの場合は動的にパスを構築
            let fileURL = imageDirectoryURL.appendingPathComponent(pathOrFileName)
            return UIImage(contentsOfFile: fileURL.path)
        }
        
        /// 指定されたローカルパスまたはファイル名の画像ファイルを削除
        /// - Parameter pathOrFileName: 削除するファイルのローカルパス（file://形式）またはファイル名
        /// - Returns: 削除に成功した場合はtrue
        public static func deleteImage(at pathOrFileName: String) -> Bool {
            let fileURL: URL
            
            // TODO: file://スキームの後方互換性サポート - 将来的に削除予定
            // file://スキームの場合は絶対パス（後方互換性のため）
            if pathOrFileName.hasPrefix("file://") {
                guard let url = URL(string: pathOrFileName) else { return false }
                fileURL = url
            } else {
                // ファイル名のみの場合は動的にパスを構築
                fileURL = imageDirectoryURL.appendingPathComponent(pathOrFileName)
            }
            
            do {
                try FileManager.default.removeItem(at: fileURL)
                return true
            } catch {
                print("画像削除に失敗: \(error)")
                return false
            }
        }

    #endif
}

/// 画像保存関連のエラー
public enum ImageStorageError: Error, LocalizedError {
    case imageCompressionFailed
    case fileNotFound
    case saveLocationNotAvailable
    
    public var errorDescription: String? {
        switch self {
        case .imageCompressionFailed:
            return "画像の圧縮に失敗しました"
        case .fileNotFound:
            return "画像ファイルが見つかりません"
        case .saveLocationNotAvailable:
            return "画像の保存場所にアクセスできません"
        }
    }
}
