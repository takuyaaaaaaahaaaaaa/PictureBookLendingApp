/// アラート表示状態を管理する共通State
struct AlertState {
    var isPresented: Bool = false
    var title: String = ""
    var message: String = ""
    var type: DialogType = .error
    
    /// ダイアログの種類
    enum DialogType {
        /// エラーダイアログ
        case error
        /// 成功ダイアログ
        case success
        /// 確認ダイアログ
        case confirmation
        /// 情報ダイアログ
        case info
    }
    
    static func error(_ message: String) -> AlertState {
        AlertState(isPresented: true, title: "エラー", message: message, type: .error)
    }
    
    static func success(_ message: String) -> AlertState {
        AlertState(isPresented: true, title: "完了", message: message, type: .success)
    }
    
    static func confirmation(_ title: String, message: String) -> AlertState {
        AlertState(isPresented: true, title: title, message: message, type: .confirmation)
    }
    
    static func info(_ title: String, message: String = "") -> AlertState {
        AlertState(isPresented: true, title: title, message: message, type: .info)
    }
}
