import Foundation
import Observation
import PictureBookLendingDomain

/**
 * 貸出管理に関するエラー
 */
enum LendingModelError: Error, Equatable {
    /// 指定された貸出情報が見つからない場合のエラー
    case loanNotFound
    /// 指定された利用者が見つからない場合のエラー
    case userNotFound
    /// 指定された絵本が見つからない場合のエラー
    case bookNotFound
    /// 絵本がすでに貸出中の場合のエラー
    case bookAlreadyLent
    /// その他の貸出処理失敗エラー
    case lendingFailed
    /// その他の返却処理失敗エラー
    case returnFailed
}

/**
 * 貸出管理モデル
 *
 * 絵本の貸出・返却を管理するモデルクラスです。
 * - 絵本の貸出
 * - 絵本の返却
 * - 貸出中の絵本の一覧取得
 * - 全貸出履歴の取得
 * - 特定の絵本の貸出履歴
 * - 特定の利用者の貸出履歴
 * などの機能を提供します。
 */
@Observable class LendingModel {
    
    /// 書籍管理モデル
    private let bookModel: BookModel
    
    /// 利用者管理モデル
    private let userModel: UserModel
    
    /// 貸出リポジトリ
    private let repository: LoanRepository
    
    /// キャッシュ用の貸出情報リスト
    private var loans: [Loan] = []
    
    /**
     * イニシャライザ
     *
     * - Parameters:
     *   - bookModel: 書籍管理モデル
     *   - userModel: 利用者管理モデル
     *   - repository: 貸出リポジトリ
     */
    init(bookModel: BookModel, userModel: UserModel, repository: LoanRepository) {
        self.bookModel = bookModel
        self.userModel = userModel
        self.repository = repository
        
        // 初期データのロード
        do {
            self.loans = try repository.fetchAll()
        } catch {
            print("初期データのロードに失敗しました: \(error)")
            self.loans = []
        }
    }
    
    /**
     * 絵本を貸し出す
     *
     * - Parameters:
     *   - bookId: 貸し出す絵本のID
     *   - userId: 借りる利用者のID
     *   - dueDate: 返却期限日
     * - Returns: 作成された貸出情報
     * - Throws: 貸出処理に失敗した場合は `LendingModelError` を投げます
     */
    func lendBook(bookId: UUID, userId: UUID, dueDate: Date) throws -> Loan {
        // 絵本の存在確認
        guard let _ = bookModel.findBookById(bookId) else {
            throw LendingModelError.bookNotFound
        }
        
        // 利用者の存在確認
        guard let _ = userModel.findUserById(userId) else {
            throw LendingModelError.userNotFound
        }
        
        // 貸出中かどうかのチェック
        if isBookLent(bookId: bookId) {
            throw LendingModelError.bookAlreadyLent
        }
        
        // 貸出情報の作成
        let loan = Loan(
            id: UUID(),
            bookId: bookId,
            userId: userId,
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
            throw LendingModelError.lendingFailed
        }
    }
    
    /**
     * 絵本を返却する
     *
     * - Parameter loanId: 返却する貸出情報のID
     * - Returns: 更新された貸出情報
     * - Throws: 返却処理に失敗した場合は `LendingModelError` を投げます
     */
    func returnBook(loanId: UUID) throws -> Loan {
        // 貸出情報を検索
        guard let loanIndex = loans.firstIndex(where: { $0.id == loanId }) else {
            // リポジトリからも検索
            do {
                if try repository.findById(loanId) == nil {
                    throw LendingModelError.loanNotFound
                }
            } catch {
                throw LendingModelError.loanNotFound
            }
            
            throw LendingModelError.loanNotFound
        }
        
        // すでに返却済みかチェック
        if loans[loanIndex].isReturned {
            throw LendingModelError.returnFailed
        }
        
        // 返却処理：返却日を設定
        let updatedLoan = loans[loanIndex]
        let returnedLoan = Loan(
            id: updatedLoan.id,
            bookId: updatedLoan.bookId,
            userId: updatedLoan.userId,
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
            throw LendingModelError.returnFailed
        }
    }
    
    /**
     * 絵本が現在貸出中かどうかを確認する
     *
     * - Parameter bookId: 確認する絵本のID
     * - Returns: 貸出中の場合はtrue、そうでなければfalse
     */
    func isBookLent(bookId: UUID) -> Bool {
        // 現在のloansから貸出中かどうかを確認
        return loans.contains { loan in
            loan.bookId == bookId && !loan.isReturned
        }
    }
    
    /**
     * 貸出情報を最新の状態に更新する
     * 
     * リポジトリから最新のデータを取得して内部キャッシュを更新します。
     */
    func refreshLoans() {
        refreshActiveLoans()
    }
    
    /**
     * 貸出中の貸出情報を最新の状態に更新
     */
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
    
    /**
     * 現在貸出中の全貸出情報を取得する
     *
     * - Returns: 貸出中の貸出情報リスト
     */
    func getActiveLoans() -> [Loan] {
        refreshActiveLoans()
        return loans.filter { !$0.isReturned }
    }
    
    /**
     * 全ての貸出履歴を取得する
     *
     * - Returns: 全ての貸出情報リスト
     */
    func getAllLoans() -> [Loan] {
        return loans
    }
    
    /**
     * 指定された利用者の貸出履歴を取得する
     *
     * - Parameter userId: 取得したい利用者のID
     * - Returns: 指定された利用者の貸出情報リスト
     */
    func getLoansByUser(userId: UUID) -> [Loan] {
        do {
            return try repository.findByUserId(userId)
        } catch {
            print("利用者の貸出履歴の取得に失敗しました: \(error)")
            return loans.filter { $0.userId == userId }
        }
    }
    
    /**
     * 指定された絵本の貸出履歴を取得する
     *
     * - Parameter bookId: 取得したい絵本のID
     * - Returns: 指定された絵本の貸出情報リスト
     */
    func getLoansByBook(bookId: UUID) -> [Loan] {
        do {
            return try repository.findByBookId(bookId)
        } catch {
            print("絵本の貸出履歴の取得に失敗しました: \(error)")
            return loans.filter { $0.bookId == bookId }
        }
    }
}