
/**
 * アラート表示状態を管理する共通State
 */
struct AlertState {
    var isPresented: Bool = false
    var title: String = ""
    var message: String = ""
    
    static func error(_ message: String) -> AlertState {
        AlertState(isPresented: true, title: "エラー", message: message)
    }
    
    static func success(_ message: String) -> AlertState {
        AlertState(isPresented: true, title: "成功", message: message)
    }
    
    static func confirmation(_ title: String, message: String) -> AlertState {
        AlertState(isPresented: true, title: title, message: message)
    }
}