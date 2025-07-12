import PictureBookLendingModel
import PictureBookLendingUI

/**
 * Model クラスの UI プロトコル準拠
 * 
 * UI モジュールで定義されたプロトコルに Model クラスを準拠させる
 * ためのエクステンションを定義します。
 */

// MARK: - Protocol Conformance

extension BookModel: BookModelProtocol {}
extension UserModel: UserModelProtocol {}
extension LendingModel: LendingModelProtocol {}