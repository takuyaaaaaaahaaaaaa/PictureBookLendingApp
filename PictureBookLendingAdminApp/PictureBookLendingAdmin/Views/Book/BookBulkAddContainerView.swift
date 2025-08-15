import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import PictureBookLendingModel
import PictureBookLendingUI
import SwiftUI

/// 絵本一括追加のContainer View
struct BookBulkAddContainerView: View {
    @Environment(BookModel.self) private var bookModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var inputText = ""
    @State private var processedBooks: [ParsedBookEntry] = []
    @State private var isProcessing = false
    @State private var alertState = AlertState()
    
    // RegisterModelを使用して検索機能を利用
    @State private var registerModel: RegisterModel
    
    init() {
        // RegisterModelを初期化
        let repositoryFactory = SwiftDataRepositoryFactory.shared
        let gateway = repositoryFactory.makeBookSearchGateway()
        let normalizer = GoogleBooksOptimizedNormalizer()
        let repository = repositoryFactory.makeBookRepository()
        
        self._registerModel = State(
            initialValue: RegisterModel(
                gateway: gateway,
                normalizer: normalizer,
                repository: repository
            )
        )
    }
    
    var body: some View {
        BookBulkAddView(
            inputText: $inputText,
            processedBooks: processedBooks,
            isProcessing: isProcessing,
            onTextChange: handleTextChange,
            onStartProcessing: handleStartProcessing,
            onSave: handleSave,
            onCancel: handleCancel
        )
        .alert(alertState.title, isPresented: $alertState.isPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertState.message)
        }
    }
    
    // MARK: - Action Handlers
    
    private func handleTextChange(_ text: String) {
        inputText = text
        // テキストが変更されたら処理結果をクリア
        if processedBooks.count > 0 {
            processedBooks = []
        }
    }
    
    private func handleStartProcessing() {
        Task {
            await processBookEntries()
        }
    }
    
    private func handleSave() {
        Task {
            await saveBooksToModel()
        }
    }
    
    private func handleCancel() {
        dismiss()
    }
    
    // MARK: - Business Logic
    
    private func processBookEntries() async {
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            let parsedEntries = try parseInputText(inputText)
            var processedEntries: [ParsedBookEntry] = []
            
            // 各エントリに対して検索を実行
            for entry in parsedEntries {
                var updatedEntry = entry
                
                // タイトルで検索を実行
                await performSingleSearch(for: entry) { foundBook in
                    if let book = foundBook {
                        updatedEntry = ParsedBookEntry(
                            managementNumber: entry.managementNumber,
                            inputTitle: entry.inputTitle,
                            foundBook: book
                        )
                    }
                }
                
                processedEntries.append(updatedEntry)
            }
            
            processedBooks = processedEntries
            
        } catch {
            alertState = .error("テキスト解析でエラーが発生しました: \(error.localizedDescription)")
        }
    }
    
    private func saveBooksToModel() async {
        do {
            var savedCount = 0
            
            for entry in processedBooks {
                if let book = entry.foundBook {
                    // 管理番号と五十音グループを設定
                    let kanaGroup = KanaGroup.from(text: book.title)
                    let bookWithManagementNumber = Book(
                        id: book.id,
                        title: book.title,
                        author: book.author,
                        isbn13: book.isbn13,
                        publisher: book.publisher,
                        publishedDate: book.publishedDate,
                        description: book.description,
                        smallThumbnail: book.smallThumbnail,
                        thumbnail: book.thumbnail,
                        targetAge: book.targetAge,
                        pageCount: book.pageCount,
                        categories: book.categories,
                        managementNumber: entry.managementNumber,
                        kanaGroup: kanaGroup
                    )
                    
                    _ = try bookModel.registerBook(bookWithManagementNumber)
                    savedCount += 1
                }
            }
            
            alertState = .info("\(savedCount)件の絵本を追加しました")
            
            // 成功したら画面を閉じる
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                dismiss()
            }
            
        } catch {
            alertState = .error("保存でエラーが発生しました: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Search Logic
    
    private func performSingleSearch(
        for entry: ParsedBookEntry, completion: @escaping (Book?) -> Void
    ) async {
        // RegisterModelに検索条件をセット
        registerModel.searchTitle = entry.inputTitle
        registerModel.searchAuthor = ""
        registerModel.clearSearchResults()
        
        do {
            try registerModel.searchBooks()
            
            // RegisterModelの状態変更を監視
            await withCheckedContinuation { continuation in
                var isCompleted = false
                
                // 検索状態の変化を監視するTask
                let monitorTask = Task {
                    let maxWaitTime = 10.0  // 最大待機時間を10秒に延長
                    let startTime = Date()
                    
                    while !isCompleted && Date().timeIntervalSince(startTime) < maxWaitTime {
                        if !registerModel.isSearching {
                            // 検索完了
                            if let bestMatch = findBestMatch(
                                for: entry.inputTitle, in: registerModel.searchResults)
                            {
                                completion(bestMatch.book)
                            } else {
                                completion(nil)
                            }
                            isCompleted = true
                            continuation.resume()
                            return
                        }
                        
                        try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1秒待機
                    }
                    
                    // タイムアウト
                    if !isCompleted {
                        print("Search timeout for: \(entry.inputTitle)")
                        completion(nil)
                        isCompleted = true
                        continuation.resume()
                    }
                }
                
                // 初期状態で既に完了している場合の処理
                if !registerModel.isSearching {
                    monitorTask.cancel()
                    if let bestMatch = findBestMatch(
                        for: entry.inputTitle, in: registerModel.searchResults)
                    {
                        completion(bestMatch.book)
                    } else {
                        completion(nil)
                    }
                    isCompleted = true
                    continuation.resume()
                }
            }
            
        } catch {
            print("Search error for \(entry.inputTitle): \(error)")
            completion(nil)
        }
    }
    
    // MARK: - Parsing Logic
    
    private func parseInputText(_ text: String) throws -> [ParsedBookEntry] {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        var entries: [ParsedBookEntry] = []
        
        for line in lines {
            let components = line.components(separatedBy: .whitespaces)
                .filter { !$0.isEmpty }
            
            if components.count >= 2 {
                let managementNumber = components[0]
                let title = components[1...].joined(separator: " ")
                
                entries.append(
                    ParsedBookEntry(
                        managementNumber: managementNumber,
                        inputTitle: title
                    )
                )
            }
        }
        
        return entries
    }
    
    private func findBestMatch(for inputTitle: String, in results: [ScoredBook]) -> ScoredBook? {
        // スコアが最も高い結果を返す（0.5以上のもののみ）
        return
            results
            .filter { $0.score >= 0.5 }
            .max(by: { $0.score < $1.score })
    }
}

#Preview {
    let mockFactory = MockRepositoryFactory()
    
    BookBulkAddContainerView()
        .environment(BookModel(repository: mockFactory.bookRepository))
}
