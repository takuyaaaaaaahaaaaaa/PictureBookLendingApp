import SwiftUI

/// Preparation controls shared by settings and the first cover search.
public struct CoverPreparationView: View {
    let status: String
    let explanation: String
    let isBusy: Bool
    let canRetry: Bool
    let canSearch: Bool
    let onRetry: () -> Void
    let onSearch: (() -> Void)?

    public init(
        status: String, explanation: String, isBusy: Bool, canRetry: Bool,
        canSearch: Bool, onRetry: @escaping () -> Void, onSearch: (() -> Void)? = nil
    ) {
        self.status = status
        self.explanation = explanation
        self.isBusy = isBusy
        self.canRetry = canRetry
        self.canSearch = canSearch
        self.onRetry = onRetry
        self.onSearch = onSearch
    }

    public var body: some View {
        Form {
            Section {
                Label("表紙で本を探すための準備", systemImage: "camera.viewfinder")
                    .font(.headline)
                Text(status).accessibilityIdentifier("coverPreparation.status")
                if isBusy { ProgressView("準備状況を更新しています") }
                Text(explanation)
                    .foregroundStyle(.secondary)
            }
            Section {
                if let onSearch, canSearch {
                    Button("準備済みの本から検索", systemImage: "camera.viewfinder", action: onSearch)
                        .accessibilityIdentifier("coverPreparation.search")
                }
                Button("未処理の表紙を再試行", systemImage: "arrow.clockwise", action: onRetry)
                    .disabled(!canRetry)
                    .accessibilityIdentifier("coverPreparation.retry")
            } footer: {
                Text("表紙画像がない本は準備できません。図書管理から表紙画像を追加してください。")
            }
            Section("準備について") {
                Text("登録した表紙の特徴を端末内に保存します。準備済みの特徴は再利用し、不足・変更分だけ処理します。")
                Text("外部画像しかない本は、画像の取得・再取得に通信が必要です。カメラ画像や検索用の特徴量を認識サーバーへ送りません。")
                Text("準備は画面を閉じても続きます。見つからない本は、貸出画面でタイトル・著者から検索できます。")
            }
        }
        .navigationTitle("表紙検索の準備")
        .navigationBarTitleDisplayMode(.inline)
    }
}
