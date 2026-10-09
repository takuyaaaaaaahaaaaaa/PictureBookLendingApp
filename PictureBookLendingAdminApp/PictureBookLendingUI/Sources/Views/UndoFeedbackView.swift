import SwiftUI

/// 取り消し可能な操作のフィードバック表示状態
///
/// 「元に戻す」ボタン付きのフィードバックカード（一定時間で自動消滅）を制御します。
/// 確認ダイアログの代わりに「即実行＋取り消し可能」のフィードバックを提供します。
public struct UndoFeedback: Equatable, Sendable {
    /// フィードバックが表示中かどうか
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
    
    /// フィードバックを表示する
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
    
    /// フィードバックを非表示にする
    public mutating func dismiss() {
        isPresented = false
    }
}

/// 取り消し可能な操作のフィードバックカードPresentation View
///
/// 成功フィードバック（`SuccessFeedbackView`）と同じ視覚言語の中央カードに、
/// 大きな「元に戻す」ボタンを添えて表示します。
/// 離れた位置やお年寄りでも視認できるよう、アイコン・文字・ボタンを大きめにしています。
public struct UndoFeedbackView: View {
    /// チェックアイコンのサイズ（Dynamic Typeに追従してスケール）
    @ScaledMetric(relativeTo: .largeTitle) private var iconSize: CGFloat = 64
    
    let message: String
    let onUndo: () -> Void
    
    private enum Layout {
        static let spacing: CGFloat = 16
        static let padding: CGFloat = 32
        static let cornerRadius: CGFloat = 20
    }
    
    public init(message: String, onUndo: @escaping () -> Void) {
        self.message = message
        self.onUndo = onUndo
    }
    
    public var body: some View {
        VStack(spacing: Layout.spacing) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: iconSize))
                .symbolRenderingMode(.palette)
                .foregroundStyle(AppColor.borrowActionForeground, AppColor.borrowAction)
            
            Text(message)
                .font(.title3.bold())
                .multilineTextAlignment(.center)
            
            // 主役は「返却しました」の報告。取り消しは脇役の非常口なので
            // 強調スタイルにしない（反射的なOK連打タップによる誤取り消しを防ぐ）
            Button("元に戻す", action: onUndo)
                .buttonStyle(.bordered)
                .controlSize(.large)
        }
        .padding(Layout.padding)
        .background {
            ReturnLoanCardBackground(
                cornerRadius: Layout.cornerRadius,
                surface: AppColor.borrowerCardSurface,
                borderWidth: 1.5)
        }
    }
}

private enum UndoFeedbackConstants {
    static let displayDuration: Duration = .seconds(3)
    static let transitionDuration: TimeInterval = 0.3
    static let initialScale: CGFloat = 0.8
}

/// カードの描画だけを担当する。Sheetへ再表示してもタイマーは増やさない。
private struct UndoFeedbackCardModifier: ViewModifier {
    let feedback: UndoFeedback
    let isVisible: Bool
    let onUndo: () -> Void

    func body(content: Content) -> some View {
        content
            .overlay {
                if isVisible && feedback.isPresented {
                    UndoFeedbackView(message: feedback.message, onUndo: onUndo)
                        .transition(.scale(scale: UndoFeedbackConstants.initialScale).combined(with: .opacity))
                }
            }
            .animation(.spring(duration: UndoFeedbackConstants.transitionDuration), value: feedback.isPresented)
    }
}

/// 表示時間と成功ハプティクスを管理するModifier
private struct UndoFeedbackModifier: ViewModifier {
    @Binding var feedback: UndoFeedback
    let onUndo: () -> Void

    func body(content: Content) -> some View {
        content
            .undoFeedbackCard(feedback, onUndo: handleUndoTap)
            .sensoryFeedback(.success, trigger: feedback.occurrenceCount)
            .task(id: feedback.occurrenceCount) {
                guard feedback.isPresented else { return }
                try? await Task.sleep(for: UndoFeedbackConstants.displayDuration)
                guard !Task.isCancelled else { return }
                feedback.dismiss()
            }
    }

    private func handleUndoTap() {
        feedback.dismiss()
        onUndo()
    }
}

extension View {
    /// タイマー・ハプティクスを追加せず、別の表示先へ同じ取り消しカードを描画する。
    public func undoFeedbackCard(
        _ feedback: UndoFeedback, isVisible: Bool = true, onUndo: @escaping () -> Void
    ) -> some View {
        modifier(UndoFeedbackCardModifier(feedback: feedback, isVisible: isVisible, onUndo: onUndo))
    }

    /// 「元に戻す」付きフィードバックカード（中央表示・自動消滅・ハプティクス付き）をオーバーレイ表示する
    ///
    /// - Parameters:
    ///   - feedback: フィードバックの表示状態
    ///   - onUndo: 「元に戻す」タップ時の動作（取り消し対象は `feedback.targetId` で識別）
    public func undoFeedback(
        _ feedback: Binding<UndoFeedback>, onUndo: @escaping () -> Void
    ) -> some View {
        modifier(UndoFeedbackModifier(feedback: feedback, onUndo: onUndo))
    }
}

#Preview {
    @Previewable @State var feedback = UndoFeedback()
    
    List {
        Button("返却する") {
            feedback.show("『はらぺこあおむし』を返却しました", targetId: UUID())
        }
    }
    .undoFeedback($feedback) {
        print("元に戻す: \(String(describing: feedback.targetId))")
    }
}

#Preview("返却完了カード") {
    ZStack {
        LibrarySurfaceBackgroundView()
        UndoFeedbackView(message: "『おすしがふくをかいにきた』を返却しました", onUndo: {})
    }
}
