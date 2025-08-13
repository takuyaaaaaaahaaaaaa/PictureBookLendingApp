import Foundation
import Observation
import PictureBookLendingDomain

/// 貸出管理に関するエラー
public enum LoanModelError: Error, Equatable, LocalizedError {
    /// 指定された貸出情報が見つからない場合のエラー
    case loanNotFound
    /// 指定された利用者が見つからない場合のエラー
    case userNotFound
    /// 指定された絵本が見つからない場合のエラー
    case bookNotFound
    /// 絵本がすでに貸出中の場合のエラー
    case bookAlreadyLent
    /// 利用者の貸出可能上限を超えた場合のエラー
    case maxBooksPerUserExceeded
    /// その他の貸出処理失敗エラー
    case lendingFailed
    /// その他の返却処理失敗エラー
    case returnFailed
    
    public var errorDescription: String? {
        switch self {
        case .loanNotFound:
            return "指定された貸出情報が見つかりません"
        case .userNotFound:
            return "指定された利用者が見つかりません"
        case .bookNotFound:
            return "指定された絵本が見つかりません"
        case .bookAlreadyLent:
            return "この絵本は既に貸出中です"
        case .maxBooksPerUserExceeded:
            return "貸出可能な上限冊数を超えています"
        case .lendingFailed:
            return "貸出処理に失敗しました"
        case .returnFailed:
            return "返却処理に失敗しました"
        }
    }
}

/// 貸出管理モデル
///
/// 絵本の貸出・返却を管理するモデルクラスです。
/// - 絵本の貸出
/// - 絵本の返却
/// - 貸出中の絵本の一覧取得
/// - 全貸出履歴の取得
/// - 特定の絵本の貸出履歴
/// - 特定の利用者の貸出履歴
/// などの機能を提供します。
@Observable
@MainActor
public class LoanModel {
    
    /// 貸出リポジトリ
    private let repository: LoanRepositoryProtocol
    
    /// 絵本リポジトリ
    private let bookRepository: BookRepositoryProtocol
    
    /// 利用者リポジトリ
    private let userRepository: UserRepositoryProtocol
    
    /// 貸出設定リポジトリ
    private let loanSettingsRepository: LoanSettingsRepositoryProtocol
    
    /// キャッシュ用の貸出情報リスト
    private var loans: [Loan] = []
    
    /// イニシャライザ
    ///
    /// - Parameters:
    ///   - repository: 貸出リポジトリ
    ///   - bookRepository: 絵本リポジトリ
    ///   - userRepository: 利用者リポジトリ
    ///   - loanSettingsRepository: 貸出設定リポジトリ
    public init(
        repository: LoanRepositoryProtocol,
        bookRepository: BookRepositoryProtocol,
        userRepository: UserRepositoryProtocol,
        loanSettingsRepository: LoanSettingsRepositoryProtocol
    ) {
        self.repository = repository
        self.bookRepository = bookRepository
        self.userRepository = userRepository
        self.loanSettingsRepository = loanSettingsRepository
        
        // 初期データのロード
        do {
            self.loans = try repository.fetchAll()
        } catch {
            print("初期データのロードに失敗しました: \(error)")
            self.loans = []
        }
    }
    
    /// 絵本を貸し出す（設定値から返却期限を自動計算）
    ///
    /// - Parameters:
    ///   - bookId: 貸し出す絵本のID
    ///   - userId: 借りる利用者のID
    /// - Returns: 作成された貸出情報
    /// - Throws: 貸出処理に失敗した場合は `LoanModelError` を投げます
    public func lendBook(bookId: UUID, userId: UUID) throws -> Loan {
        // 絵本の存在確認
        do {
            _ = try bookRepository.findById(bookId)
        } catch {
            throw LoanModelError.bookNotFound
        }
        
        // 利用者の存在確認と取得
        let user: User
        do {
            guard let foundUser = try userRepository.findById(userId) else {
                throw LoanModelError.userNotFound
            }
            user = foundUser
        } catch {
            throw LoanModelError.userNotFound
        }
        
        // 貸出中かどうかのチェック
        if isBookLent(bookId: bookId) {
            throw LoanModelError.bookAlreadyLent
        }
        
        // 利用者の貸出可能上限チェック
        let settings = loanSettingsRepository.fetch()
        let currentUserLoans = getUserActiveLoans(userId: userId)
        if currentUserLoans.count >= settings.maxBooksPerUser {
            throw LoanModelError.maxBooksPerUserExceeded
        }
        
        // 返却期限日を設定から自動計算
        let dueDate = settings.calculateDueDate(from: Date())
        
        // 貸出情報の作成（User情報を含める）
        let loan = Loan(
            id: UUID(),
            bookId: bookId,
            user: user,
            loanDate: Date(),
            dueDate: dueDate,
            returnedDate: nil
        )
        
        do {
            // リポジトリに保存
            let savedLoan = try repository.save(loan)
            // キャッシュに追加
            loans.append(savedLoan)
            return savedLoan
        } catch {
            throw LoanModelError.lendingFailed
        }
    }
    
    /// 絵本を返却する
    ///
    /// - Parameter loanId: 返却する貸出情報のID
    /// - Returns: 更新された貸出情報
    /// - Throws: 返却処理に失敗した場合は `LoanModelError` を投げます
    public func returnBook(loanId: UUID) throws -> Loan {
        // 貸出情報を検索
        guard let loanIndex = loans.firstIndex(where: { $0.id == loanId }) else {
            // リポジトリからも検索
            do {
                if try repository.findById(loanId) == nil {
                    throw LoanModelError.loanNotFound
                }
            } catch {
                throw LoanModelError.loanNotFound
            }
            
            throw LoanModelError.loanNotFound
        }
        
        // すでに返却済みかチェック
        if loans[loanIndex].isReturned {
            throw LoanModelError.returnFailed
        }
        
        // 返却処理：返却日を設定
        let updatedLoan = loans[loanIndex]
        let returnedLoan = Loan(
            id: updatedLoan.id,
            bookId: updatedLoan.bookId,
            user: updatedLoan.user,
            loanDate: updatedLoan.loanDate,
            dueDate: updatedLoan.dueDate,
            returnedDate: Date()
        )
        
        do {
            // リポジトリで更新
            let result = try repository.update(returnedLoan)
            
            // キャッシュも更新
            loans[loanIndex] = result
            
            return result
        } catch {
            throw LoanModelError.returnFailed
        }
    }
    
    /// 絵本IDから絵本を返却する
    ///
    /// - Parameter bookId: 返却する絵本のID
    /// - Returns: 更新された貸出情報
    /// - Throws: 返却処理に失敗した場合は `LoanModelError` を投げます
    @discardableResult
    public func returnBook(bookId: UUID) throws -> Loan {
        // 指定された絵本の現在の貸出情報を検索
        guard let currentLoan = loans.first(where: { $0.bookId == bookId && !$0.isReturned }) else {
            // キャッシュにない場合はリポジトリから検索
            do {
                let allLoans = try repository.fetchActiveLoans()
                if let repositoryLoan = allLoans.first(where: {
                    $0.bookId == bookId && !$0.isReturned
                }) {
                    // 見つかった場合はキャッシュを更新してから返却処理
                    loans = allLoans
                    return try returnBook(loanId: repositoryLoan.id)
                }
            } catch {
                throw LoanModelError.loanNotFound
            }
            
            throw LoanModelError.loanNotFound
        }
        
        // 見つかった貸出情報のIDで返却処理を実行
        return try returnBook(loanId: currentLoan.id)
    }
    
    /// 絵本が現在貸出中かどうかを確認する
    ///
    /// - Parameter bookId: 確認する絵本のID
    /// - Returns: 貸出中の場合はtrue、そうでなければfalse
    public func isBookLent(bookId: UUID) -> Bool {
        // 現在のloansから貸出中かどうかを確認
        return loans.contains { loan in
            loan.bookId == bookId && !loan.isReturned
        }
    }
    
    /// 絵本の現在の貸出情報を取得する
    ///
    /// - Parameter bookId: 取得したい絵本のID
    /// - Returns: 現在貸出中の場合はLoanオブジェクト、貸出中でない場合はnil
    public func getCurrentLoan(bookId: UUID) -> Loan? {
        return loans.first { loan in
            loan.bookId == bookId && !loan.isReturned
        }
    }
    
    /// 貸出情報を最新の状態に更新する
    ///
    /// リポジトリから最新のデータを取得して内部キャッシュを更新します。
    public func refreshLoans() {
        refreshActiveLoans()
    }
    
    /// 貸出中の貸出情報を最新の状態に更新
    private func refreshActiveLoans() {
        do {
            let activeLoans = try repository.fetchActiveLoans()
            
            // アクティブな貸出のみを更新
            for activeLoan in activeLoans {
                if let index = loans.firstIndex(where: { $0.id == activeLoan.id }) {
                    loans[index] = activeLoan
                } else {
                    loans.append(activeLoan)
                }
            }
            
            // 返却済みの貸出情報も更新
            let allLoans = try repository.fetchAll()
            for loan in allLoans where loan.isReturned {
                if let index = loans.firstIndex(where: { $0.id == loan.id }) {
                    loans[index] = loan
                } else {
                    loans.append(loan)
                }
            }
        } catch {
            print("貸出情報の更新に失敗しました: \(error)")
        }
    }
    
    /// 現在貸出中の全貸出情報を取得する
    ///
    /// - Returns: 貸出中の貸出情報リスト
    public func getActiveLoans() -> [Loan] {
        refreshActiveLoans()
        return loans.filter { !$0.isReturned }
    }
    
    /// 全ての貸出履歴を取得する
    ///
    /// - Returns: 全ての貸出情報リスト
    public func getAllLoans() -> [Loan] {
        return loans
    }
    
    /// 指定された利用者の貸出履歴を取得する
    ///
    /// - Parameter userId: 取得したい利用者のID
    /// - Returns: 指定された利用者の貸出情報リスト
    public func getLoansByUser(userId: UUID) -> [Loan] {
        do {
            return try repository.findByUserId(userId)
        } catch {
            print("利用者の貸出履歴の取得に失敗しました: \(error)")
            return loans.filter { $0.user.id == userId }
        }
    }
    
    /// 指定された利用者の現在アクティブな貸出情報を取得する
    ///
    /// - Parameter userId: 取得したい利用者のID
    /// - Returns: 指定された利用者の現在アクティブな貸出情報リスト
    public func getUserActiveLoans(userId: UUID) -> [Loan] {
        return loans.filter { $0.user.id == userId && !$0.isReturned }
    }
    
    /// 指定された絵本の貸出履歴を取得する
    ///
    /// - Parameter bookId: 取得したい絵本のID
    /// - Returns: 指定された絵本の貸出情報リスト
    public func getLoansByBook(bookId: UUID) -> [Loan] {
        do {
            return try repository.findByBookId(bookId)
        } catch {
            print("絵本の貸出履歴の取得に失敗しました: \(error)")
            return loans.filter { $0.bookId == bookId }
        }
    }
}
