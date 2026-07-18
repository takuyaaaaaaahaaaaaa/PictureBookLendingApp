import SwiftUI

/// お祝いフィードバックの表示状態
///
/// 貸出が節目に達したときの紙吹雪＋メッセージカードの表示を制御します。
/// `SuccessFeedback` と同じ作法（自動消滅・`occurrenceCount` による再発火）に、
/// タップでスキップできる点が加わります。
public struct CelebrationFeedback: Equatable, Sendable {
    /// フィードバックが表示中かどうか
    public var isPresented: Bool
    /// お祝いのタイトル（例：「10回よんだよ！」）
    public var title: String
    /// お祝いのメッセージ（例：「○○さん、『ぐりとぐら』を10回かりました！」）
    public var message: String
    /// `show(title:message:)` が呼ばれた累計回数
    ///
    /// SwiftUIは「値の変化」しか検知できないため、表示中にもう一度 `show` を
    /// 呼んでも `isPresented`（true→true）では再表示を検知できない。
    /// この値を `sensoryFeedback`・`task(id:)`・紙吹雪のシードに渡すことで、
    /// 毎回ハプティクスが鳴り、タイマーと紙吹雪が新しい表示から再スタートする。
    public private(set) var occurrenceCount: Int

    public init() {
        self.isPresented = false
        self.title = ""
        self.message = ""
        self.occurrenceCount = 0
    }

    /// お祝いフィードバックを表示する
    public mutating func show(title: String, message: String) {
        self.title = title
        self.message = message
        isPresented = true
        occurrenceCount += 1
    }

    /// お祝いフィードバックを非表示にする
    public mutating func dismiss() {
        isPresented = false
    }
}

/// お祝いフィードバックのPresentation View
///
/// クラッカーのアイコンとお祝いメッセージのカードを表示します。
/// タップスキップの判定はModifier側で行うため、カード自体はタップを透過します。
public struct CelebrationFeedbackView: View {
    /// クラッカーアイコンのサイズ（Dynamic Typeに追従してスケール）
    @ScaledMetric(relativeTo: .largeTitle) private var iconSize: CGFloat = 64

    let title: String
    let message: String

    private enum Layout {
        static let spacing: CGFloat = 12
        static let padding: CGFloat = 32
        static let cornerRadius: CGFloat = 20
    }

    public init(title: String, message: String) {
        self.title = title
        self.message = message
    }

    public var body: some View {
        VStack(spacing: Layout.spacing) {
            Image(systemName: "party.popper.fill")
                .font(.system(size: iconSize))
                .foregroundStyle(.orange)

            Text(title)
                .font(.title2.bold())

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

/// 紙吹雪アニメーション
///
/// 画面下の左右から紙片が「パンッ」と舞い上がり、重力に引かれて舞い落ちる。
/// 紙片は毎フレーム、シード付き乱数から決定的に再生成するため、
/// 状態として保持せず軽量に描画できる。
struct ConfettiView: View {
    /// 紙片の散り方を決めるシード（表示ごとに変えると散り方も変わる）
    let seed: Int

    @State private var startDate = Date()

    private enum Constants {
        /// 紙片の枚数
        static let particleCount = 90
        /// 打ち上げから消えるまでの時間
        static let duration: TimeInterval = 3.0
        /// 重力加速度（pt/s²）
        static let gravity: Double = 700
        /// フェードアウトを開始する進行割合
        static let fadeStart: Double = 0.7
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let elapsed = timeline.date.timeIntervalSince(startDate)
                guard elapsed >= 0, elapsed <= Constants.duration else { return }

                let progress = elapsed / Constants.duration
                let opacity =
                    progress < Constants.fadeStart
                    ? 1.0
                    : 1.0 - (progress - Constants.fadeStart) / (1.0 - Constants.fadeStart)

                var generator = SeededRandomNumberGenerator(seed: UInt64(max(seed, 0)))
                for _ in 0..<Constants.particleCount {
                    let particle = ConfettiParticle(using: &generator, in: size)
                    particle.draw(
                        in: context,
                        elapsed: elapsed,
                        gravity: Constants.gravity,
                        opacity: opacity
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

/// 紙吹雪の紙片1枚
///
/// 発射位置・初速・色・回転などをシード付き乱数から決め、
/// 経過時間に応じた位置（放物線）と姿勢を計算して描画する。
private struct ConfettiParticle {
    /// 紙片の色（システムカラーから選ぶ）
    private static let colors: [Color] = [
        .red, .orange, .yellow, .green, .mint, .blue, .purple, .pink,
    ]

    private enum Constants {
        /// 発射位置の左右端からの割合
        static let launchInset: Double = 0.12
        /// 打ち上げの基準角度（度）。左の発射台は右上へ、右の発射台は左上へ
        static let launchAngleFromVertical: Double = 20
        /// 打ち上げ角度のばらつき（度）
        static let launchAngleSpread: Double = 28
        /// 打ち上げ初速の範囲（pt/s）
        static let speedRange: ClosedRange<Double> = 500...1100
        /// 紙片の辺の長さの範囲（pt）
        static let sideRange: ClosedRange<Double> = 8...14
        /// 回転速度の範囲（rad/s）
        static let spinSpeedRange: ClosedRange<Double> = 2...8
        /// ひらひら（面の反転）速度の範囲（rad/s）
        static let flutterSpeedRange: ClosedRange<Double> = 3...8
    }

    let start: CGPoint
    let velocity: CGVector
    let color: Color
    let size: CGSize
    let initialAngle: Double
    let spinSpeed: Double
    let flutterSpeed: Double
    let flutterPhase: Double

    init(using generator: inout some RandomNumberGenerator, in canvasSize: CGSize) {
        let isFromLeft = Bool.random(using: &generator)
        let launchX =
            isFromLeft
            ? canvasSize.width * Constants.launchInset
            : canvasSize.width * (1 - Constants.launchInset)
        start = CGPoint(x: launchX, y: canvasSize.height)

        // 真上を基準に、左の発射台は内側（右上）へ、右の発射台は内側（左上）へ傾ける
        let baseAngle =
            isFromLeft
            ? -90 + Constants.launchAngleFromVertical
            : -90 - Constants.launchAngleFromVertical
        let spread = Double.random(
            in: -Constants.launchAngleSpread...Constants.launchAngleSpread, using: &generator)
        let angle = (baseAngle + spread) * .pi / 180
        let speed = Double.random(in: Constants.speedRange, using: &generator)
        velocity = CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed)

        color = Self.colors.randomElement(using: &generator) ?? .pink
        let side = Double.random(in: Constants.sideRange, using: &generator)
        size = CGSize(width: side, height: side * 0.6)
        initialAngle = Double.random(in: 0...(2 * .pi), using: &generator)
        spinSpeed = Double.random(in: Constants.spinSpeedRange, using: &generator)
        flutterSpeed = Double.random(in: Constants.flutterSpeedRange, using: &generator)
        flutterPhase = Double.random(in: 0...(2 * .pi), using: &generator)
    }

    func draw(in context: GraphicsContext, elapsed: TimeInterval, gravity: Double, opacity: Double)
    {
        let position = CGPoint(
            x: start.x + velocity.dx * elapsed,
            y: start.y + velocity.dy * elapsed + 0.5 * gravity * elapsed * elapsed
        )

        // GraphicsContextは値型なので、コピーに変換をかければ他の紙片に影響しない
        var particleContext = context
        particleContext.opacity = opacity
        particleContext.translateBy(x: position.x, y: position.y)
        particleContext.rotate(by: .radians(initialAngle + spinSpeed * elapsed))
        // ひらひら：横方向のスケールを振動させ、紙片が翻る様子を表す
        particleContext.scaleBy(x: cos(flutterSpeed * elapsed + flutterPhase), y: 1)

        let rect = CGRect(
            x: -size.width / 2, y: -size.height / 2,
            width: size.width, height: size.height
        )
        particleContext.fill(Path(rect), with: .color(color))
    }
}

/// シード付き乱数生成器（SplitMix64）
///
/// 同じシードから常に同じ乱数列を生成する。紙吹雪の紙片を
/// 毎フレーム同じ散り方で再生成するために使う。
private struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

/// お祝いフィードバックを画面全体にオーバーレイ表示するModifier
///
/// 紙吹雪とメッセージカードを重ね、表示後は自動で終了する。
/// 節目は特別な瞬間なので日常の✓カードより長く見せるが、
/// 行列を止めないよう画面のどこかをタップすればすぐスキップできる
/// （DESIGN_PRINCIPLES.md「フィードバック設計」の節目のお祝い）。
private struct CelebrationFeedbackModifier: ViewModifier {
    @Binding var feedback: CelebrationFeedback
    /// 自動終了までの表示時間
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
                    // 表示中の再showでも紙吹雪が最初から舞い直すよう、表示回数でidを切り替える
                    ConfettiView(seed: feedback.occurrenceCount)
                        .id(feedback.occurrenceCount)
                        .overlay {
                            CelebrationFeedbackView(
                                title: feedback.title,
                                message: feedback.message
                            )
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { feedback.dismiss() }
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
    /// お祝いフィードバック（紙吹雪＋メッセージカード、自動終了・タップでスキップ）をオーバーレイ表示する
    ///
    /// - Parameter displayDuration: 自動終了までの表示時間。既定は3.5秒
    ///   （DESIGN_PRINCIPLES.md「フィードバック設計」の節目のお祝い：3〜4秒で自動終了）
    public func celebrationFeedback(
        _ feedback: Binding<CelebrationFeedback>,
        displayDuration: Duration = .seconds(3.5)
    ) -> some View {
        modifier(CelebrationFeedbackModifier(feedback: feedback, displayDuration: displayDuration))
    }
}

#Preview {
    @Previewable @State var feedback = CelebrationFeedback()

    List {
        Button("同じ図書の節目") {
            feedback.show(
                title: "10回よんだよ！",
                message: "さくらさん、『ぐりとぐら』を10回かりました！"
            )
        }
        Button("いろいろな図書の節目") {
            feedback.show(
                title: "20冊目！",
                message: "はるとさん、これで20冊目の図書です！おめでとう！"
            )
        }
    }
    .celebrationFeedback($feedback)
}
