import SwiftUI

/// Display-only information for identifying an unprepared book, including duplicate titles.
public struct PendingCoverBookDisplay: Identifiable, Equatable, Sendable {
    public let id: UUID
    let title: String
    let author: String
    let managementNumber: String

    public init(id: UUID, title: String, author: String, managementNumber: String) {
        self.id = id
        self.title = title
        self.author = author
        self.managementNumber = managementNumber
    }
}

/// Preparation controls shared by settings and the first cover search.
public struct CoverPreparationView: View {
    let status: String
    let explanation: String
    let isBusy: Bool
    let canRetry: Bool
    let canSearch: Bool
    let onRetry: () -> Void
    let onSearch: (() -> Void)?
    let pendingBooks: [PendingCoverBookDisplay]
    let onSelectPendingBook: (UUID) -> Void

    public init(
        status: String, explanation: String, isBusy: Bool, canRetry: Bool,
        canSearch: Bool, onRetry: @escaping () -> Void, onSearch: (() -> Void)? = nil,
        pendingBooks: [PendingCoverBookDisplay],
        onSelectPendingBook: @escaping (UUID) -> Void
    ) {
        self.status = status
        self.explanation = explanation
        self.isBusy = isBusy
        self.canRetry = canRetry
        self.canSearch = canSearch
        self.onRetry = onRetry
        self.onSearch = onSearch
        self.pendingBooks = pendingBooks
        self.onSelectPendingBook = onSelectPendingBook
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
                Text("表紙画像がない本は準備できません。未処理の本を選び、表紙画像を確認・追加してください。")
            }
            if !pendingBooks.isEmpty {
                Section {
                    ForEach(pendingBooks) { book in
                        Button {
                            onSelectPendingBook(book.id)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(book.title).foregroundStyle(.primary)
                                    if !book.author.isEmpty {
                                        Text(book.author).font(.subheadline).foregroundStyle(
                                            .secondary)
                                    }
                                    Text(book.managementNumber)
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "pencil")
                                    .foregroundStyle(.tint)
                                    .accessibilityHidden(true)
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("図書の編集画面で表紙を確認します")
                    }
                } header: {
                    Text("未処理の本（\(pendingBooks.count)冊）")
                } footer: {
                    Text("本を選ぶと、表紙画像を確認・追加できます。準備が完了した本は一覧から消えます。")
                }
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
