import Foundation
import PictureBookLendingDomain

// MARK: - Protocol Definitions for UI Module

public protocol BookModelProtocol {
    func findBookById(_ id: UUID) -> Book?
}

public protocol UserModelProtocol {
    func findUserById(_ id: UUID) -> User?
}

public protocol LendingModelProtocol {
    // UI表示に必要な最小限のインターフェース
}
