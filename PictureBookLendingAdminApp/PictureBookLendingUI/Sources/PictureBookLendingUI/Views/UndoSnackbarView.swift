import SwiftUI

/// 取り消し可能な操作のスナックバー表示状態
///
/// 「元に戻す」ボタン付きのスナックバー（一定時間で自動消滅）を制御します。
/// 確認ダイアログの代わりに「即実行＋取り消し可能」のフィードバックを提供します。
public struct UndoFeedback: Equatable, Sendable {
    /// スナックバーが表示中かどうか
    public var isPresented: Bool
    /// 表示するメッセージ（例：「『はらぺこあおむし』を返却しました」）
    public var message: String
    /// 取り消し対象を呼び出し側で識別するためのID（例：貸出記録のID）
    public var targetId: UUID?
    /// `show(_:targetId:)` が呼ばれた累計回数
    ///
    /// SwiftUIは「値の変化」しか検知できないため、表示中にもう一度 `show` を
    /// 呼んでも `isPresented`（true→true）では再表示を検知できない。
    /// この値を `sensoryFeedback` と `task(id:)` のトリガに渡すことで、
    /// 連続操作時にも毎回ハプティクスが鳴り、自動消滅タイマーが新しい表示の
    /// タイミングから再スタートする。
    public private(set) var occurrenceCount: Int
    
    public init() {
        self.isPresented = false
        self.message = ""
        self.targetId = nil
        self.occurrenceCount = 0
    }
    
    /// スナックバーを表示する
    ///
    /// - Parameters:
    ///   - message: 表示するメッセージ
    ///   - targetId: 取り消し対象を識別するID
    public mutating func show(_ message: String, targetId: UUID) {
        self.message = message
        self.targetId = targetId
        isPresented = true
        occurrenceCount += 1
    }
    
    /// スナックバーを非表示にする
    public mutating func dismiss() {
        isPresented = false
    }
}

/// 取り消し可能な操作のスナックバーPresentation View
///
/// メッセージと「元に戻す」ボタンを表示します。
public struct UndoSnackbarView: View {
    let message: String
    let onUndo: () -> Void
    
    private enum Layout {
        static let spacing: CGFloat = 16
        static let horizontalPadding: CGFloat = 20
        static let verticalPadding: CGFloat = 14
        static let cornerRadius: CGFloat = 14
    }
    
    public init(message: String, onUndo: @escaping () -> Void) {
        self.message = message
        self.onUndo = onUndo
    }
    
    public var body: some View {
        HStack(spacing: Layout.spacing) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            
            Text(message)
                .font(.subheadline)
                .lineLimit(1)
            
            Button("元に戻す", action: onUndo)
                .font(.subheadline.bold())
        }
        .padding(.horizontal, Layout.horizontalPadding)
        .padding(.vertical, Layout.verticalPadding)
        .background(
            .regularMaterial,
            in: RoundedRectangle(cornerRadius: Layout.cornerRadius)
        )
    }
}

/// スナックバーを画面下部にオーバーレイ表示するModifier
///
/// 表示後は自動で消滅し、表示時に成功ハプティクスを発生させます。
/// 「元に戻す」タップ時は `onUndo` を呼び、スナックバーを閉じます。
private struct UndoSnackbarModifier: ViewModifier {
    @Binding var feedback: UndoFeedback
    let onUndo: () -> Void
    
    private enum Constants {
        /// 自動消滅までの表示時間（DESIGN_PRINCIPLES.md「フィードバック設計」準拠）
        static let displayDuration: Duration = .seconds(5)
        /// 出現・消滅アニメーションの時間
        static let transitionDuration: TimeInterval = 0.3
        /// 画面下端からの間隔
        static let bottomPadding: CGFloat = 16
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if feedback.isPresented {
                    UndoSnackbarView(message: feedback.message, onUndo: handleUndoTap)
                        .padding(.bottom, Constants.bottomPadding)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(
                .spring(duration: Constants.transitionDuration), value: feedback.isPresented
            )
            .sensoryFeedback(.success, trigger: feedback.occurrenceCount)
            .task(id: feedback.occurrenceCount) {
                guard feedback.isPresented else { return }
                try? await Task.sleep(for: Constants.displayDuration)
                feedback.dismiss()
            }
    }
    
    private func handleUndoTap() {
        feedback.dismiss()
        onUndo()
    }
}

extension View {
    /// 「元に戻す」付きスナックバー（自動消滅・ハプティクス付き）をオーバーレイ表示する
    ///
    /// - Parameters:
    ///   - feedback: スナックバーの表示状態
    ///   - onUndo: 「元に戻す」タップ時の動作（取り消し対象は `feedback.targetId` で識別）
    public func undoSnackbar(
        _ feedback: Binding<UndoFeedback>, onUndo: @escaping () -> Void
    ) -> some View {
        modifier(UndoSnackbarModifier(feedback: feedback, onUndo: onUndo))
    }
}

#Preview {
    @Previewable @State var feedback = UndoFeedback()
    
    List {
        Button("返却する") {
            feedback.show("『はらぺこあおむし』を返却しました", targetId: UUID())
        }
    }
    .undoSnackbar($feedback) {
        print("元に戻す: \(String(describing: feedback.targetId))")
    }
}
