import PictureBookLendingDomain
import SwiftUI

/// 貸出確認画面のプレゼンテーションビュー
public struct LoanConfirmationView: View {
    let book: Book
    let user: User
    let classGroup: ClassGroup
    let dueDate: Date
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    public init(
        book: Book,
        user: User,
        classGroup: ClassGroup,
        dueDate: Date,
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.book = book
        self.user = user
        self.classGroup = classGroup
        self.dueDate = dueDate
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // タイトル
                Text("貸出確認")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                // 貸出情報カード
                VStack(spacing: 16) {
                    // 絵本情報
                    LoanInfoSection(title: "絵本") {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(book.title)
                                .font(.headline)
                            Text("著者: \(book.author)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    // 利用者情報
                    LoanInfoSection(title: "利用者") {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.name)
                                .font(.headline)
                            Text("\(classGroup.name) • \(classGroup.ageGroup)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    // 返却期限
                    LoanInfoSection(title: "返却期限") {
                        Text(dueDate, style: .date)
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                Spacer()
                
                // 確認ボタン
                VStack(spacing: 12) {
                    Button(action: onConfirm) {
                        Text("貸出を確定する")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    
                    Button(action: onCancel) {
                        Text("キャンセル")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            #if os(iOS)
                .toolbar(.hidden, for: .navigationBar)
            #endif
        }
    }
}

/// 貸出情報セクション
private struct LoanInfoSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                content
            }
            
            Spacer()
        }
    }
}

#Preview {
    LoanConfirmationView(
        book: Book(title: "はらぺこあおむし", author: "エリック・カール"),
        user: User(name: "山田太郎", classGroupId: UUID()),
        classGroup: ClassGroup(name: "ひよこ組", ageGroup: "0歳児", year: 2025),
        dueDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
        onConfirm: {},
        onCancel: {}
    )
}
