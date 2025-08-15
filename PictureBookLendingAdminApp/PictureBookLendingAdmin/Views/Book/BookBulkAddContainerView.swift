import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import PictureBookLendingModel
import PictureBookLendingUI
import SwiftUI

/// 連続登録用のアイテム
struct FailedBookItem: Identifiable {
    let id = UUID()
    let entry: ParsedBookEntry
    let currentIndex: Int
    let totalCount: Int
}

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
    @State private var activeFailedBook: FailedBookItem?
    
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
        .sheet(item: $activeFailedBook) { failedBookItem in
            NavigationStack {
                BookFormContainerView(
                    mode: .add,
                    initialBook: createBookFromFailedEntry(failedBookItem.entry),
                    onSave: { savedBook in
                        handleIndividualBookSaved(savedBook)
                    }
                )
                .navigationTitle(
                    "絵本を追加 (\(failedBookItem.currentIndex + 1)/\(failedBookItem.totalCount))"
                )
                #if !os(macOS)
                    .navigationBarTitleDisplayMode(.inline)
                #endif
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
            activeFailedBook = FailedBookItem(
                entry: failedBooks[currentBookIndex],
                currentIndex: currentBookIndex,
                totalCount: failedBooks.count
            )
        }
    }
    
    private func handleIndividualBookSaved(_ savedBook: Book) {
        // 保存された本に基づいてprocessedBooksを更新
        updateProcessedBooksStatus(savedBook: savedBook)
        
        // 現在の本を次へ進める
        currentBookIndex += 1
        
        // 残りの未登録本を再計算
        let remainingFailedBooks = processedBooks.filter { $0.foundBook == nil }
        
        // まだ登録する本があるかチェック
        if currentBookIndex < failedBooks.count && !remainingFailedBooks.isEmpty {
            // 次の未登録本を探す
            if let nextFailedEntry = remainingFailedBooks.first,
                let nextIndex = failedBooks.firstIndex(where: {
                    $0.managementNumber == nextFailedEntry.managementNumber
                }),
                nextIndex >= currentBookIndex
            {
                
                // 次の本を設定
                activeFailedBook = FailedBookItem(
                    entry: nextFailedEntry,
                    currentIndex: remainingFailedBooks.count - remainingFailedBooks.count + 1,
                    totalCount: remainingFailedBooks.count
                )
            } else {
                // 登録可能な本がない場合は終了
                activeFailedBook = nil
                alertState = .info("登録可能な絵本がありません")
            }
        } else {
            // 全ての本の登録が完了
            activeFailedBook = nil
            let successMessage =
                remainingFailedBooks.isEmpty
                ? "個別登録が必要な絵本の登録が全て完了しました。\n※最後に画面右上の保存ボタンを押し忘れないようにお気をつけください。" : "絵本の個別登録が完了しました"
            alertState = .info(successMessage)
        }
    }
    
    private func handleSkipCurrentBook() {
        currentBookIndex += 1
        
        // 残りの未登録本を再計算
        let remainingFailedBooks = processedBooks.filter { $0.foundBook == nil }
        
        if currentBookIndex < failedBooks.count && !remainingFailedBooks.isEmpty {
            // 次の未登録本を探す
            if let nextFailedEntry = remainingFailedBooks.first(where: { entry in
                failedBooks.firstIndex(where: { $0.managementNumber == entry.managementNumber })
                    ?? 0 >= currentBookIndex
            }) {
                // 次の本を設定
                let currentProgress =
                    remainingFailedBooks.count
                    - remainingFailedBooks.filter { entry in
                        failedBooks.firstIndex(where: {
                            $0.managementNumber == entry.managementNumber
                        }) ?? 0 >= currentBookIndex
                    }.count + 1
                
                activeFailedBook = FailedBookItem(
                    entry: nextFailedEntry,
                    currentIndex: currentProgress,
                    totalCount: remainingFailedBooks.count
                )
            } else {
                // スキップできる本がない場合は終了
                activeFailedBook = nil
            }
        } else {
            // 全てスキップまたは完了
            activeFailedBook = nil
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
    
    private func updateProcessedBooksStatus(savedBook: Book) {
        // 保存された本の管理番号に対応するprocessedBooksのエントリを更新
        if let managementNumber = savedBook.managementNumber,
            let index = processedBooks.firstIndex(where: {
                $0.managementNumber == managementNumber
            })
        {
            // 既存のエントリを保存された本で更新
            processedBooks[index] = ParsedBookEntry(
                managementNumber: managementNumber,
                inputTitle: processedBooks[index].inputTitle,
                foundBook: savedBook
            )
        }
    }
    
    private func refreshProcessedBooks() {
        // 全ての処理済み本のステータスをデータベースから確認して更新
        for (index, entry) in processedBooks.enumerated() {
            // 管理番号で既存の本を検索
            if let existingBook = bookModel.findBookByManagementNumber(entry.managementNumber) {
                // 既に登録済みの場合はステータスを更新
                processedBooks[index] = ParsedBookEntry(
                    managementNumber: entry.managementNumber,
                    inputTitle: entry.inputTitle,
                    foundBook: existingBook
                )
            }
        }
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
            
            // 初期処理後に既存の登録状況をチェック
            refreshProcessedBooks()
            
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
