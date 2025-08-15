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
        
        /// 画像を保存してローカルパスを返す
        /// - Parameters:
        ///   - image: 保存する画像
        ///   - fileName: ファイル名（拡張子なし、デフォルトでUUID生成）
        /// - Returns: 保存されたファイルのローカルパス
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
            
            // ローカルパスを返す（file://スキームを含む）
            return fileURL.absoluteString
        }
        
        /// ローカルパスから画像を読み込む
        /// - Parameter localPath: ローカルファイルパス
        /// - Returns: 読み込まれた画像（失敗時はnil）
        public static func loadImage(from localPath: String) -> UIImage? {
            guard let url = URL(string: localPath) else { return nil }
            
            // file://スキームの場合はローカルファイル
            if url.scheme == "file" {
                return UIImage(contentsOfFile: url.path)
            }
            
            // それ以外は従来のURL（リモート画像など）として扱う
            return nil
        }
        
        /// 指定されたローカルパスの画像ファイルを削除
        /// - Parameter localPath: 削除するファイルのローカルパス
        /// - Returns: 削除に成功した場合はtrue
        public static func deleteImage(at localPath: String) -> Bool {
            guard let url = URL(string: localPath),
                url.scheme == "file"
            else { return false }
            
            do {
                try FileManager.default.removeItem(at: url)
                return true
            } catch {
                print("画像削除に失敗: \(error)")
                return false
            }
        }
        
        /// ローカル画像パスかどうかを判定
        /// - Parameter path: 判定する文字列
        /// - Returns: ローカル画像パスの場合はtrue
        public static func isLocalImagePath(_ path: String?) -> Bool {
            guard let path = path,
                let url = URL(string: path)
            else { return false }
            return url.scheme == "file"
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
