import Kingfisher
import PictureBookLendingDomain
import SwiftUI
import TipKit

#if canImport(UIKit)
    import UIKit
#endif

/// 自動入力機能の案内用Tip
struct AutoFillTip: Tip {
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

/// 絵本フォームのPresentation View
///
/// 純粋なUI表示のみを担当し、NavigationStack、alert等の
/// 画面制御はContainer Viewに委譲します。
public struct BookFormView<AutoFillButton: View>: View {
    @Binding var book: Book
    let mode: BookFormMode
    let autoFillButton: AutoFillButton?
    let onSave: () -> Void
    let onCancel: () -> Void
    let onReset: (() -> Void)
    let onCameraTap: (() -> Void)?
    
    private let autoFillTip = AutoFillTip()
    
    public init(
        book: Binding<Book>,
        mode: BookFormMode,
        @ViewBuilder autoFillButton: () -> AutoFillButton,
        onSave: @escaping () -> Void,
        onCancel: @escaping () -> Void,
        onReset: @escaping () -> Void,
        onCameraTap: (() -> Void)? = nil
    ) {
        self._book = book
        self.mode = mode
        self.autoFillButton = autoFillButton()
        self.onSave = onSave
        self.onCancel = onCancel
        self.onReset = onReset
        self.onCameraTap = onCameraTap
    }
    
    public init(
        book: Binding<Book>,
        mode: BookFormMode,
        onSave: @escaping () -> Void,
        onCancel: @escaping () -> Void,
        onReset: @escaping () -> Void,
        onCameraTap: (() -> Void)? = nil
    ) where AutoFillButton == EmptyView {
        self._book = book
        self.mode = mode
        self.autoFillButton = nil
        self.onSave = onSave
        self.onCancel = onCancel
        self.onReset = onReset
        self.onCameraTap = onCameraTap
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
                    "絵本の説明・あらすじ",
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
            ToolbarItem(placement: .cancellationAction) {
                Button("キャンセル") {
                    onCancel()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button(isEditMode ? "保存" : "追加") {
                    onSave()
                }
                .disabled(!isValidInput)
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
                
                if let thumbnailURL = book.thumbnail ?? book.smallThumbnail {
                    BookImageView(imageURL: thumbnailURL) {
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
            
            // カメラボタン
            #if canImport(UIKit)
                if let onCameraTap = onCameraTap, CameraUtility.isCameraAvailable {
                    Button(action: onCameraTap) {
                        HStack {
                            Image(systemName: "camera")
                            Text("写真を撮影")
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            #endif
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
        .navigationTitle("絵本を追加")
    }
}
