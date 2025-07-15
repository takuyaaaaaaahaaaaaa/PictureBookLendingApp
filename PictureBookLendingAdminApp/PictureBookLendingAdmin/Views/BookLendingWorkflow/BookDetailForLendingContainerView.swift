import PictureBookLendingDomain
import PictureBookLendingModel
import PictureBookLendingUI
import SwiftUI

/// 貸出用絵本詳細のコンテナビュー
///
/// 選択された絵本の詳細情報を表示し、組選択画面への遷移を提供します。
/// 貸出状態の確認と貸出可能性の判定も行います。
struct BookDetailForLendingContainerView: View {
    let book: Book
    
    @Environment(LendingModel.self) private var lendingModel
    @Environment(\.navigationPath) private var navigationPath
    
    @State private var alertState = AlertState()
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 20) {
            // 絵本詳細表示
            BookDetailView(
                book: book,
                showEditButton: false,
                showDeleteButton: false,
                additionalActions: {
                    lendingActionButton
                }
            )
            
            Spacer()
        }
        .navigationTitle(book.title)
        .navigationBarTitleDisplayMode(.large)
        .alert(alertState.title, isPresented: $alertState.isPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertState.message)
        }
    }
    
    @ViewBuilder
    private var lendingActionButton: some View {
        if isBookCurrentlyLoaned {
            // 貸出中の場合
            VStack(spacing: 8) {
                Label("貸出中", systemImage: "person.fill.checkmark")
                    .foregroundStyle(.orange)
                    .font(.headline)
                
                if let currentLoan = currentLoan {
                    Text("返却予定: \(currentLoan.dueDate, style: .date)")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
        } else {
            // 貸出可能な場合
            Button("この絵本を貸し出す") {
                proceedToGroupSelection()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isLoading)
        }
    }
    
    private var isBookCurrentlyLoaned: Bool {
        lendingModel.isBookCurrentlyLoaned(book.id)
    }
    
    private var currentLoan: Loan? {
        lendingModel.currentLoans.first { $0.bookId == book.id }
    }
    
    private func proceedToGroupSelection() {
        guard !isBookCurrentlyLoaned else {
            alertState = AlertState(
                title: "この絵本は貸出中です",
                message: "「\(book.title)」は現在貸出中のため、新たに貸し出すことはできません。"
            )
            return
        }
        
        // 組選択画面へ遷移
        navigationPath.wrappedValue.append(BookLendingDestination.groupSelection(book))
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
        title: "サンプル絵本",
        author: "作者名",
        targetAge: 5,
        publishedAt: Date()
    )
    
    NavigationStack {
        BookDetailForLendingContainerView(book: sampleBook)
            .environment(lendingModel)
    }
}