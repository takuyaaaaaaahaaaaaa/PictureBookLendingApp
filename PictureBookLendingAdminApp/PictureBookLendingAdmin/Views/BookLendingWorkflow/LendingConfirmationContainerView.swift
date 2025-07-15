import PictureBookLendingDomain
import PictureBookLendingModel
import SwiftUI

/// 貸出確認のコンテナビュー
///
/// 選択された絵本と園児の情報を確認し、最終的な貸出処理を実行する画面です。
/// 返却期限の設定や確認メッセージの表示を行います。
struct LendingConfirmationContainerView: View {
    let book: Book
    let user: User
    
    @Environment(LendingModel.self) private var lendingModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.navigationPath) private var navigationPath
    
    @State private var dueDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var alertState = AlertState()
    @State private var isProcessing = false
    
    private var isAgeSuitable: Bool {
        book.isSuitable(for: user.age)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 確認ヘッダー
                VStack(spacing: 12) {
                    Image(systemName: "book.and.wrench")
                        .font(.system(size: 48))
                        .foregroundStyle(.blue)
                    
                    Text("貸出内容の確認")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("以下の内容で貸出を実行しますか？")
                        .foregroundStyle(.secondary)
                }
                
                // 貸出情報カード
                VStack(spacing: 16) {
                    // 絵本情報
                    HStack {
                        Image(systemName: "book.fill")
                            .foregroundStyle(.blue)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("絵本")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(book.title)
                                .font(.headline)
                            Text("著者: \(book.author)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    
                    // 園児情報
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundStyle(.green)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("園児")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(user.name)
                                .font(.headline)
                            HStack {
                                Text("年齢: \(user.age)歳")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                if isAgeSuitable {
                                    Label("適齢", systemImage: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                } else {
                                    Label("対象年齢外", systemImage: "exclamationmark.triangle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                    
                    // 返却期限設定
                    VStack(alignment: .leading, spacing: 8) {
                        Text("返却期限")
                            .font(.headline)
                        
                        DatePicker(
                            "返却期限",
                            selection: $dueDate,
                            in: Date()...,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        
                        Text("通常は1週間後に設定されています")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
                    
                    // 年齢適合性警告
                    if !isAgeSuitable {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("対象年齢について")
                                    .font(.headline)
                                    .foregroundStyle(.orange)
                                Text("この絵本の対象年齢は\(book.targetAge)歳以上です。\(user.name)くん/ちゃんは\(user.age)歳のため、対象年齢外となります。")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                
                // アクションボタン
                VStack(spacing: 12) {
                    Button("貸出を実行") {
                        Task {
                            await executeLending()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(isProcessing)
                    
                    Button("キャンセル") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .disabled(isProcessing)
                }
            }
            .padding()
        }
        .navigationTitle("貸出確認")
        .navigationBarTitleDisplayMode(.inline)
        .alert(alertState.title, isPresented: $alertState.isPresented) {
            if alertState.title == "貸出完了" {
                Button("OK") {
                    // ルートに戻る
                    navigationPath.wrappedValue = NavigationPath()
                }
            } else {
                Button("OK", role: .cancel) {}
            }
        } message: {
            Text(alertState.message)
        }
    }
    
    private func executeLending() async {
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            try await lendingModel.lendBook(
                bookId: book.id,
                userId: user.id,
                dueDate: dueDate
            )
            
            alertState = AlertState(
                title: "貸出完了",
                message: "「\(book.title)」を\(user.name)くん/ちゃんに貸し出しました。\n返却期限: \(dueDate.formatted(date: .abbreviated, time: .omitted))"
            )
        } catch {
            alertState = AlertState(
                title: "貸出エラー",
                message: "貸出処理に失敗しました: \(error.localizedDescription)"
            )
        }
    }
}

#Preview {
    let mockFactory = MockRepositoryFactory()
    let lendingModel = LendingModel(
        repository: mockFactory.loanRepository,
        bookRepository: mockFactory.bookRepository,
        userRepository: mockFactory.userRepository
    )
    
    let sampleBook = Book(
        id: UUID(),
        title: "はらぺこあおむし",
        author: "エリック・カール",
        targetAge: 3,
        publishedAt: Date()
    )
    
    let sampleUser = User(
        id: UUID(),
        name: "田中太郎",
        age: 5,
        classGroupId: UUID()
    )
    
    NavigationStack {
        LendingConfirmationContainerView(book: sampleBook, user: sampleUser)
            .environment(lendingModel)
    }
}