import CoreImage.CIFilterBuiltins
import SwiftUI

/// URLをQRコードとして表示するPresentation View
///
/// 保護者向けの報告フォームなど、印刷・掲示して院外の利用者に
/// スキャンしてもらうことを想定している。
public struct FeedbackQRCodeView: View {
    @State private var qrCGImage: CGImage?

    let url: URL
    let handoutURL: URL?

    public init(url: URL, handoutURL: URL? = nil) {
        self.url = url
        self.handoutURL = handoutURL
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Group {
                    if let qrCGImage {
                        Image(decorative: qrCGImage, scale: 1)
                            .interpolation(.none)
                            .resizable()
                    } else {
                        ProgressView()
                    }
                }
                .frame(width: 280, height: 280)

                Text("スマートフォンのカメラで読み取ってください")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let handoutURL {
                    ShareLink(item: handoutURL) {
                        Label("案内PDFを共有", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.borderedProminent)

                    Text("共有画面から「ファイルに保存」や印刷を選べます。保護者への配布にご利用ください。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    Text("案内PDFを読み込めませんでした。アプリを開き直してお試しください。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .task {
            qrCGImage = Self.makeQRCode(from: url.absoluteString)
        }
    }

    private static func makeQRCode(from string: String) -> CGImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        guard let outputImage = filter.outputImage else { return nil }
        let scaled = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        return CIContext().createCGImage(scaled, from: scaled.extent)
    }
}

#Preview {
    FeedbackQRCodeView(url: URL(string: "https://example.com")!)
}
