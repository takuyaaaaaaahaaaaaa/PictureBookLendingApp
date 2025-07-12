import Foundation

/**
 * ローディング状態を管理する共通State
 */
struct LoadingState {
    var isLoading: Bool = false
    var message: String = "読み込み中..."
    
    static let loading = LoadingState(isLoading: true)
    static let idle = LoadingState(isLoading: false)
    
    static func loading(message: String) -> LoadingState {
        LoadingState(isLoading: true, message: message)
    }
}