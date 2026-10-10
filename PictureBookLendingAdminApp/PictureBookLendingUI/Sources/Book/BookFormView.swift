import Kingfisher
import PictureBookLendingDomain
import SwiftUI
import TipKit

#if canImport(UIKit)
    import UIKit
#endif

/// 自動入力機能の案内用Tip
struct AutoFillTip: Tip {
    // TipKitの保存領域はconfigure後にリセットできないため、再表示時はIDを更新する。
    static let replayGenerationKey = "autoFillTipReplayGeneration"

    private let replayGeneration = UserDefaults.standard.integer(forKey: replayGenerationKey)

    var id: String {
        let originalID = String(describing: Self.self)
        // 既存ユーザーの表示履歴を引き継ぐため、初回はTipKitの既定IDを使う。
        return replayGeneration == 0 ? originalID : "\(originalID).replay.\(replayGeneration)"
    }

    var options: [any Option] {
        MaxDisplayCount(1)
    }

    var title: Text {
        Text("タイトルと著者名から自動入力")
    }

    var message: Text? {
        Text("タイトルと著者名を入力すると、書籍情報を自動検索して入力できます")
    }

    var image: Image? {
        Image(systemName: "wand.and.stars")
    }
}

public enum BookFormTipDebug {
    public static func replayAutoFillTip() {
        let defaults = UserDefaults.standard
        let nextGeneration = defaults.integer(forKey: AutoFillTip.replayGenerationKey) + 1
        defaults.set(nextGeneration, forKey: AutoFillTip.replayGenerationKey)
    }
}

/// 絵本フォームのPresentation View
///
/// 純粋なUI表示のみを担当し、NavigationStack、alert等の
/// 画面制御はContainer Viewに委譲します。
public struct BookFormView<AutoFillButton: View>: View {
    @Binding var book: Book
    let imageURL: String?
    let mode: BookFormMode
    let autoFillButton: AutoFillButton?
    let onSave: () -> Void
    let onCancel: () -> Void
    let onReset: (() -> Void)
    let onCameraTap: (() -> Void)?
    let onAdjustPhotoTap: (() -> Void)?
    let showsNavigationActions: Bool

    private let autoFillTip = AutoFillTip()

    public init(
        book: Binding<Book>,
        imageURL: String? = nil,
        mode: BookFormMode,
        @ViewBuilder autoFillButton: () -> AutoFillButton,
        onSave: @escaping () -> Void,
        onCancel: @escaping () -> Void,
        onReset: @escaping () -> Void,
        onCameraTap: (() -> Void)? = nil,
        onAdjustPhotoTap: (() -> Void)? = nil,
        showsNavigationActions: Bool = true
    ) {
        self._book = book
        self.imageURL = imageURL
        self.mode = mode
        self.autoFillButton = autoFillButton()
        self.onSave = onSave
        self.onCancel = onCancel
        self.onReset = onReset
        self.onCameraTap = onCameraTap
        self.onAdjustPhotoTap = onAdjustPhotoTap
        self.showsNavigationActions = showsNavigationActions
    }

    public init(
        book: Binding<Book>,
        imageURL: String? = nil,
        mode: BookFormMode,
        onSave: @escaping () -> Void,
        onCancel: @escaping () -> Void,
        onReset: @escaping () -> Void,
        onCameraTap: (() -> Void)? = nil,
        onAdjustPhotoTap: (() -> Void)? = nil,
        showsNavigationActions: Bool = true
    ) where AutoFillButton == EmptyView {
        self._book = book
        self.imageURL = imageURL
        self.mode = mode
        self.autoFillButton = nil
        self.onSave = onSave
        self.onCancel = onCancel
        self.onReset = onReset
        self.onCameraTap = onCameraTap
        self.onAdjustPhotoTap = onAdjustPhotoTap
        self.showsNavigationActions = showsNavigationActions
    }

    public var body: some View {
        Form {
            // サムネイル表示セクション
            Section(header: Text("プレビュー")) {
                thumbnailSection
            }

            Section(header: Text("基本情報（*は必須）")) {
                TextField("タイトル *", text: $book.title)
                TextField(
                    "著者",
                    text: Binding(
                        get: { book.author ?? "" },
                        set: { book.author = $0.isEmpty ? nil : $0 }
                    )
                )

                // 自動入力ボタン（タイトル・著者名の下に配置）
                if let autoFillButton = autoFillButton {
                    HStack {
                        Image(systemName: "wand.and.stars")
                            .foregroundStyle(.secondary)
                        Text("タイトルと著者名から情報を自動入力※実行回数には制限がございます。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        autoFillButton
                    }
                    .padding(.vertical, 4)
                    .popoverTip(autoFillTip)
                }

                TextField(
                    "管理番号（例: あ13）",
                    text: Binding(
                        get: { book.managementNumber ?? "" },
                        set: { book.managementNumber = $0.isEmpty ? nil : $0 }
                    ))
            }

            Section(header: Text("詳細情報（任意）")) {
                TextField(
                    "ISBN-13",
                    text: Binding(
                        get: { book.isbn13 ?? "" },
                        set: { book.isbn13 = $0.isEmpty ? nil : $0 }
                    ))
                TextField(
                    "出版社",
                    text: Binding(
                        get: { book.publisher ?? "" },
                        set: { book.publisher = $0.isEmpty ? nil : $0 }
                    ))
                TextField(
                    "出版日",
                    text: Binding(
                        get: { book.publishedDate ?? "" },
                        set: { book.publishedDate = $0.isEmpty ? nil : $0 }
                    ))
            }

            Section(header: Text("その他（任意）")) {
                Picker("対象読者", selection: $book.targetAge) {
                    Text("未選択").tag(nil as TargetAudience?)
                    ForEach(TargetAudience.allCases, id: \.self) { audience in
                        Text(audience.displayText).tag(audience as TargetAudience?)
                    }
                }
                .pickerStyle(.menu)

                TextField(
                    "ページ数",
                    text: Binding(
                        get: { book.pageCount.map(String.init) ?? "" },
                        set: { newValue in
                            if newValue.isEmpty {
                                book.pageCount = nil
                            } else if let intValue = Int(newValue), intValue >= 0 {
                                book.pageCount = intValue
                            }
                        }
                    )
                )
                #if os(iOS)
                    .keyboardType(.numberPad)
                #endif

                Picker("ひらがなグループ", selection: $book.kanaGroup) {
                    Text("未選択").tag(nil as KanaGroup?)
                    ForEach(KanaGroup.allCases, id: \.self) { kana in
                        Text(kana.displayName).tag(kana as KanaGroup?)
                    }
                }
                .pickerStyle(.menu)

            }

            Section(header: Text("説明（任意）")) {
                TextField(
                    "図書の説明・あらすじ",
                    text: Binding(
                        get: { book.description ?? "" },
                        set: { book.description = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical
                )
                .lineLimit(3...6)
            }

            // リセットボタン
            Section {
                VStack(spacing: 12) {
                    HStack {
                        Spacer()
                        Button(action: {
                            print("🔘 リセットボタンがタップされました")
                            onReset()
                        }) {
                            Label("入力項目をリセット", systemImage: "arrow.counterclockwise")
                                .font(.footnote)
                        }
                        .buttonStyle(.bordered)
                        .tint(.orange)
                        .controlSize(.small)
                        Spacer()
                    }

                    Text("フォームの内容をすべてクリアします")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)

            }
        }
        .toolbar {
            if showsNavigationActions {
                BookFormActions(
                    isEditMode: isEditMode, canSave: isValidInput,
                    onSave: onSave, onCancel: onCancel)
            }
        }
    }

    // MARK: - Computed Properties

    private var isEditMode: Bool {
        if case .edit = mode {
            return true
        }
        return false
    }

    private var isValidInput: Bool {
        !book.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    @ViewBuilder
    private var thumbnailSection: some View {
        VStack(spacing: 12) {
            HStack {
                Spacer()

                if let imageSource = imageURL {
                    BookImageView(imageURL: imageSource) {
                        Image(systemName: "book.closed")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 40))
                    }
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 150)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: "book.closed")
                        .font(.system(size: 60))
                        .foregroundStyle(.secondary)
                        .frame(height: 100)
                }

                Spacer()
            }

            VStack(spacing: 24) {
                #if canImport(UIKit)
                    if let onCameraTap, CameraUtility.isCameraAvailable {
                        Button(action: onCameraTap) {
                            HStack {
                                Image(systemName: "camera")
                                Text("写真を撮影")
                            }
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .foregroundStyle(.white)
                            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 10))
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                #endif
                if let onAdjustPhotoTap {
                    Button(action: onAdjustPhotoTap) {
                        Label("写真を調整", systemImage: "crop")
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .foregroundStyle(Color.accentColor)
                            .background(
                                Color.accentColor.opacity(0.08),
                                in: RoundedRectangle(cornerRadius: 10)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10).strokeBorder(
                                    Color.accentColor.opacity(0.4))
                            )
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: 360)
            .padding(.top, 8)
        }
    }
}

#Preview {
    @Previewable @State var sampleBook = Book(
        title: "サンプル本",
        author: "著者名",
        isbn13: "9784001234567",
        publisher: "サンプル出版",
        publishedDate: "2023-01-01",
        description: "これはサンプルの絵本です。",
        targetAge: .toddler,
        pageCount: 32,
        categories: ["絵本"],
        managementNumber: "あ13"
    )

    NavigationStack {
        BookFormView<EmptyView>(
            book: $sampleBook,
            mode: BookFormMode.add,
            onSave: {},
            onCancel: {},
            onReset: {}
        )
        .navigationTitle("図書を追加")
    }
}
