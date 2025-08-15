import PictureBookLendingDomain
import SwiftUI

/// 絵本一括追加のPresentation View
public struct BookBulkAddView: View {
    @Binding var inputText: String
    let processedBooks: [ParsedBookEntry]
    let isProcessing: Bool
    let onTextChange: (String) -> Void
    let onStartProcessing: () -> Void
    let onSave: () -> Void
    let onCancel: () -> Void
    let onRegisterFailed: ((ParsedBookEntry) -> Void)?
    
    public init(
        inputText: Binding<String>,
        processedBooks: [ParsedBookEntry],
        isProcessing: Bool,
        onTextChange: @escaping (String) -> Void,
        onStartProcessing: @escaping () -> Void,
        onSave: @escaping () -> Void,
        onCancel: @escaping () -> Void,
        onRegisterFailed: ((ParsedBookEntry) -> Void)? = nil
    ) {
        self._inputText = inputText
        self.processedBooks = processedBooks
        self.isProcessing = isProcessing
        self.onTextChange = onTextChange
        self.onStartProcessing = onStartProcessing
        self.onSave = onSave
        self.onCancel = onCancel
        self.onRegisterFailed = onRegisterFailed
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // 入力エリア
                inputSection
                
                // 処理結果エリア
                if !processedBooks.isEmpty {
                    resultsSection
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("絵本一括追加")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave()
                    }
                    .disabled(processedBooks.isEmpty || isProcessing)
                }
            }
        }
    }
    
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("絵本データ入力")
                .font(.headline)
            
            Text("管理番号とタイトルを以下の形式で入力してください：\n例: あ31 あいうえお")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            TextEditor(text: $inputText)
                .frame(minHeight: 120)
                .padding(8)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onChange(of: inputText) { _, newValue in
                    onTextChange(newValue)
                }
            
            HStack {
                Button("処理開始", systemImage: "play.fill") {
                    onStartProcessing()
                }
                .disabled(
                    inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        || isProcessing)
                
                if isProcessing {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
        }
    }
    
    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("処理結果 (\(processedBooks.count)件)")
                .font(.headline)
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(processedBooks, id: \.managementNumber) { entry in
                        BookBulkAddRowView(
                            entry: entry,
                            onRegisterFailed: onRegisterFailed
                        )
                    }
                }
            }
            .frame(maxHeight: 300)
        }
    }
}

/// 一括追加の個別行表示
struct BookBulkAddRowView: View {
    let entry: ParsedBookEntry
    let onRegisterFailed: ((ParsedBookEntry) -> Void)?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.managementNumber)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    
                    Text(entry.inputTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                if let book = entry.foundBook {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("検索結果: \(book.title)")
                            .font(.caption)
                            .foregroundStyle(.green)
                        
                        Text("著者: \(book.author ?? "不明")")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("検索結果なし")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            
            Spacer()
            
            // 失敗した場合は個別登録ボタンを表示
            if entry.foundBook == nil, let onRegisterFailed = onRegisterFailed {
                Button("個別登録") {
                    onRegisterFailed(entry)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            statusIcon
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var statusIcon: some View {
        Image(
            systemName: entry.foundBook != nil
                ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
        )
        .foregroundStyle(entry.foundBook != nil ? .green : .orange)
        .font(.title3)
    }
}

/// パースされた絵本エントリ
public struct ParsedBookEntry: Identifiable {
    public let id = UUID()
    public let managementNumber: String
    public let inputTitle: String
    public let foundBook: Book?
    
    public init(managementNumber: String, inputTitle: String, foundBook: Book? = nil) {
        self.managementNumber = managementNumber
        self.inputTitle = inputTitle
        self.foundBook = foundBook
    }
}

#Preview {
    @Previewable @State var inputText = """
        あ31 あいうえお
        あ23 あいうえおうた
        あ20 あいうえおおさま
        """
    
    let sampleBooks = [
        ParsedBookEntry(
            managementNumber: "あ31",
            inputTitle: "あいうえお",
            foundBook: Book(
                title: "あいうえお",
                author: "いもとようこ"
            )
        ),
        ParsedBookEntry(
            managementNumber: "あ23",
            inputTitle: "あいうえおうた",
            foundBook: nil
        ),
    ]
    
    BookBulkAddView(
        inputText: $inputText,
        processedBooks: sampleBooks,
        isProcessing: false,
        onTextChange: { _ in },
        onStartProcessing: {},
        onSave: {},
        onCancel: {},
        onRegisterFailed: { entry in
            print("個別登録: \(entry.managementNumber) - \(entry.inputTitle)")
        }
    )
}
