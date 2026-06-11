import SwiftUI

/// 成功フィードバックの表示状態
///
/// OKタップ不要の成功フィードバック（チェックマーク表示＋ハプティクス）を制御します。
/// `occurrenceCount` は連続表示時にハプティクスと自動消滅タイマーを再起動させるためのトリガです。
public struct SuccessFeedback: Equatable, Sendable {
    public var isPresented: Bool
    public var message: String
    public private(set) var occurrenceCount: Int
    
    public init() {
        self.isPresented = false
        self.message = ""
        self.occurrenceCount = 0
    }
    
    /// 成功フィードバックを表示する
    public mutating func show(_ message: String) {
        self.message = message
        isPresented = true
        occurrenceCount += 1
    }
    
    /// 成功フィードバックを非表示にする
    public mutating func dismiss() {
        isPresented = false
    }
}

/// 成功フィードバックのPresentation View
///
/// チェックマークとメッセージを表示します。
/// 操作を妨げないよう、タップは透過します。
public struct SuccessFeedbackView: View {
    let message: String
    
    private enum Layout {
        static let iconSize: CGFloat = 64
        static let spacing: CGFloat = 12
        static let padding: CGFloat = 32
        static let cornerRadius: CGFloat = 20
    }
    
    public init(message: String) {
        self.message = message
    }
    
    public var body: some View {
        VStack(spacing: Layout.spacing) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: Layout.iconSize))
                .foregroundStyle(.green)
            
            Text(message)
                .font(.headline)
                .multilineTextAlignment(.center)
        }
        .padding(Layout.padding)
        .background(
            .regularMaterial,
            in: RoundedRectangle(cornerRadius: Layout.cornerRadius)
        )
        .allowsHitTesting(false)
    }
}

/// 成功フィードバックを画面中央にオーバーレイ表示するModifier
///
/// 表示後は自動で消滅し、表示時に成功ハプティクスを発生させます。
/// OKタップは不要で、操作をブロックしません。
private struct SuccessFeedbackModifier: ViewModifier {
    @Binding var feedback: SuccessFeedback
    
    private enum Constants {
        /// 自動消滅までの表示時間（DESIGN_PRINCIPLES.md「フィードバック設計」準拠）
        static let displayDuration: Duration = .seconds(1.5)
        /// 出現・消滅アニメーションの時間
        static let transitionDuration: TimeInterval = 0.3
        /// 出現時の初期スケール
        static let initialScale: CGFloat = 0.8
    }
    
    func body(content: Content) -> some View {
        content
            .overlay {
                if feedback.isPresented {
                    SuccessFeedbackView(message: feedback.message)
                        .transition(
                            .scale(scale: Constants.initialScale).combined(with: .opacity))
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
}

extension View {
    /// 成功フィードバック（チェックマーク＋ハプティクス、自動消滅）をオーバーレイ表示する
    public func successFeedback(_ feedback: Binding<SuccessFeedback>) -> some View {
        modifier(SuccessFeedbackModifier(feedback: feedback))
    }
}

#Preview {
    @Previewable @State var feedback = SuccessFeedback()
    
    List {
        Button("貸出成功") {
            feedback.show("山田太郎さんに貸出しました")
        }
        Button("返却成功") {
            feedback.show("返却しました")
        }
    }
    .successFeedback($feedback)
}
