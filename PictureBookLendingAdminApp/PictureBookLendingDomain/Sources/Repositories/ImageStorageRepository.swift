import Foundation

/// 図書画像の読み書きを担当するリポジトリのプロトコル
///
/// バックアップのエクスポート/インポート時に、ローカル保存された図書画像を扱うために使用します。
public protocol ImageStorageRepositoryProtocol: Sendable {
    /// 指定したファイル名の画像データを読み込む
    /// - Parameter fileName: 画像ファイル名
    /// - Returns: 画像データ（存在しない場合はnil）
    func loadImageData(fileName: String) -> Data?
    
    /// 画像データを指定したファイル名で保存する
    /// - Parameters:
    ///   - data: 保存する画像データ
    ///   - fileName: 保存先のファイル名
    /// - Throws: 保存に失敗した場合はエラーを投げる
    func saveImageData(_ data: Data, fileName: String) throws
}
