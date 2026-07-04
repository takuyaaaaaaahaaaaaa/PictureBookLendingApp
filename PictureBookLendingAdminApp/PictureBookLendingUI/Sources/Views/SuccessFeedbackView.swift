import SwiftUI

/// 成功フィードバックの表示状態
///
/// OKタップ不要の成功フィードバック（チェックマーク表示＋ハプティクス）を制御します。
public struct SuccessFeedback: Equatable, Sendable {
    /// フィードバックが表示中かどうか
    public var isPresented: Bool
    /// 表示するメッセージ（例：「○○さんに貸出しました」）
    public var message: String
    /// `show(_:)` が呼ばれた累計回数
    ///
    /// SwiftUIは「値の変化」しか検知できないため、表示中にもう一度 `show(_:)` を
    /// 呼んでも `isPresented`（true→true）では再表示を検知できない。
    /// この値を `sensoryFeedback` と `task(id:)` のトリガに渡すことで、
    /// 連続操作時にも毎回ハプティクスが鳴り、自動消滅タイマーが新しい表示の
    /// タイミングから再スタートする。
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
    /// チェックアイコンのサイズ（Dynamic Typeに追従してスケール）
    @ScaledMetric(relativeTo: .largeTitle) private var iconSize: CGFloat = 64
    
    let message: String
    
    private enum Layout {
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
                .font(.system(size: iconSize))
                .foregroundStyle(.green)
            
            Text(message)
                .font(.title3.bold())
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
    /// 自動消滅までの表示時間
    let displayDuration: Duration
    
    private enum Constants {
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
                try? await Task.sleep(for: displayDuration)
                feedback.dismiss()
            }
    }
}

extension View {
    /// 成功フィードバック（チェックマーク＋ハプティクス、自動消滅）をオーバーレイ表示する
    ///
    /// - Parameter displayDuration: 自動消滅までの表示時間。既定は1.5秒
    ///   （DESIGN_PRINCIPLES.md「フィードバック設計」の日常の成功）。
    ///   カードの消滅が画面遷移の合図を兼ねる文脈では、読み切れるよう長めに指定できる
    public func successFeedback(
        _ feedback: Binding<SuccessFeedback>,
        displayDuration: Duration = .seconds(1.5)
    ) -> some View {
        modifier(SuccessFeedbackModifier(feedback: feedback, displayDuration: displayDuration))
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
