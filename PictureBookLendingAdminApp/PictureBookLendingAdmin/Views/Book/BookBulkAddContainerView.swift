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
    
    // 連続登録用の状態
    @State private var failedBooks: [ParsedBookEntry] = []
    @State private var currentBookIndex = 0
    @State private var isShowingIndividualForm = false
    
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
            onCancel: handleCancel,
            onRegisterFailed: handleRegisterFailed
        )
        .alert(alertState.title, isPresented: $alertState.isPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertState.message)
        }
        .sheet(isPresented: $isShowingIndividualForm) {
            if currentBookIndex < failedBooks.count {
                let failedBook = failedBooks[currentBookIndex]
                NavigationStack {
                    BookFormContainerView(
                        mode: .add,
                        initialBook: createBookFromFailedEntry(failedBook),
                        onSave: { savedBook in
                            handleIndividualBookSaved(savedBook)
                        }
                    )
                    .navigationTitle("絵本を追加 (\(currentBookIndex + 1)/\(failedBooks.count))")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("スキップ") {
                                handleSkipCurrentBook()
                            }
                        }
                    }
                }
            }
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
    
    private func handleRegisterFailed(_ entry: ParsedBookEntry) {
        // 失敗した本のみをリストアップして連続登録を開始
        failedBooks = processedBooks.filter { $0.foundBook == nil }
        if let index = failedBooks.firstIndex(where: {
            $0.managementNumber == entry.managementNumber
        }) {
            currentBookIndex = index
            isShowingIndividualForm = true
        }
    }
    
    private func handleIndividualBookSaved(_ savedBook: Book) {
        // 現在の本を次へ進める
        currentBookIndex += 1
        
        // まだ登録する本があるかチェック
        if currentBookIndex < failedBooks.count {
            // 次の本の登録へ
            // sheetは既に表示されているので、次の本が自動で表示される
        } else {
            // 全ての本の登録が完了
            isShowingIndividualForm = false
            alertState = .info("失敗した絵本の登録が完了しました")
            
            // processedBooksを更新して成功状態にする
            refreshProcessedBooks()
        }
    }
    
    private func handleSkipCurrentBook() {
        currentBookIndex += 1
        
        if currentBookIndex < failedBooks.count {
            // 次の本へ
        } else {
            // 全てスキップまたは完了
            isShowingIndividualForm = false
        }
    }
    
    private func createBookFromFailedEntry(_ entry: ParsedBookEntry) -> Book {
        // 失敗したエントリから初期値として本を作成
        let kanaGroup = KanaGroup.from(text: entry.inputTitle)
        return Book(
            title: entry.inputTitle,
            author: "",
            managementNumber: entry.managementNumber,
            kanaGroup: kanaGroup
        )
    }
    
    private func refreshProcessedBooks() {
        // 現在の処理済み本のリストを再読み込み
        // （実際の実装では、保存された本をデータベースから確認する）
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
