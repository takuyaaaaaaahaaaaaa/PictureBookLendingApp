import PictureBookLendingDomain
import Testing

@testable import PictureBookLendingInfrastructure

/// 検索精度テスト - 表記ゆれによる検索結果の違いを検証
struct SearchAccuracyTests {
    private let apiClient = GoogleBookSearchGateway()
    
    /// 「ぐりとぐら」の表記ゆれテスト
    @Test func testGuriToGuraVariations() async throws {
        let variations: [(description: String, title: String, author: String?)] = [
            ("基本形", "ぐりとぐら", "なかがわりえこ"),
            ("スペース入り", "ぐり と ぐら", "なかがわりえこ"),
            ("全角スペース", "ぐり　と　ぐら", "なかがわりえこ"),
            ("中黒区切り", "ぐり・と・ぐら", "なかがわりえこ"),
            ("著者中黒", "ぐりとぐら", "なかがわ・りえこ"),
            ("著者スペース", "ぐりとぐら", "なかがわ りえこ"),
            ("著者漢字", "ぐりとぐら", "中川李枝子"),
        ]

        print("=== 「ぐりとぐら」表記ゆれテスト ===")
        
        for variation in variations {
            do {
                let books = try await apiClient.searchBooks(
                    title: variation.title,
                    author: variation.author,
                    maxResults: 10
                )
                
                print("\n[\(variation.description)]")
                print("検索: タイトル=「\(variation.title)」, 著者=「\(variation.author ?? "なし")」")
                print("結果: \(books.count)件")
                
                if !books.isEmpty {
                    print("上位3件:")
                    for (index, book) in books.prefix(3).enumerated() {
                        print("  \(index + 1). \(book.title) - \(book.author)")
                    }
                }
            } catch {
                print("\n[\(variation.description)] - エラー: \(error)")
            }
        }
    }
    
    /// 「はらぺこあおむし」の表記ゆれテスト
    @Test func testHungryBugVariations() async throws {
        let variations: [(description: String, title: String, author: String?)] = [
            ("基本形", "はらぺこあおむし", "エリック・カール"),
            ("スペース入り", "はらぺこ あおむし", "エリック・カール"),
            ("中黒区切り", "はらぺこ・あおむし", "エリック・カール"),
            ("ハイフン区切り", "はらぺこ-あおむし", "エリック・カール"),
            ("著者スペース", "はらぺこあおむし", "エリック カール"),
            ("英語著者", "はらぺこあおむし", "Eric Carle"),
            ("原題", "The Very Hungry Caterpillar", "Eric Carle"),
        ]

        print("\n=== 「はらぺこあおむし」表記ゆれテスト ===")
        
        for variation in variations {
            do {
                let books = try await apiClient.searchBooks(
                    title: variation.title,
                    author: variation.author,
                    maxResults: 10
                )
                
                print("\n[\(variation.description)]")
                print("検索: タイトル=「\(variation.title)」, 著者=「\(variation.author ?? "なし")」")
                print("結果: \(books.count)件")
                
                if !books.isEmpty {
                    print("上位3件:")
                    for (index, book) in books.prefix(3).enumerated() {
                        print("  \(index + 1). \(book.title) - \(book.author)")
                    }
                }
            } catch {
                print("\n[\(variation.description)] - エラー: \(error)")
            }
        }
    }
    
    /// 記号・文字種の違いテスト
    @Test func testSymbolVariations() async throws {
        let testCases: [(description: String, title: String, author: String)] = [
            ("数字半角", "100万回生きたねこ", "佐野洋子"),
            ("数字全角", "１００万回生きたねこ", "佐野洋子"),
            ("数字漢数字", "百万回生きたねこ", "佐野洋子"),
            ("ハイフン", "スイミー-小さなかしこいさかなのはなし", "レオ・レオニ"),
            ("長音符", "スイミー―小さなかしこいさかなのはなし", "レオ・レオニ"),
            ("コロン", "スイミー：小さなかしこいさかなのはなし", "レオ・レオニ"),
        ]

        print("\n=== 記号・文字種違いテスト ===")
        
        for testCase in testCases {
            do {
                let books = try await apiClient.searchBooks(
                    title: testCase.title,
                    author: testCase.author,
                    maxResults: 10
                )
                
                print("\n[\(testCase.description)]")
                print("検索: 「\(testCase.title)」「\(testCase.author)」")
                print("結果: \(books.count)件")
                
                if !books.isEmpty {
                    print("トップ結果: \(books.first?.title ?? "不明")")
                }
            } catch {
                print("\n[\(testCase.description)] - エラー: \(error)")
            }
        }
    }
    
    /// 著者名の役割語テスト
    @Test func testAuthorRoleVariations() async throws {
        let variations: [(description: String, title: String, author: String)] = [
            ("著者名のみ", "からすのパンやさん", "かこさとし"),
            ("作者付き", "からすのパンやさん", "かこさとし作"),
            ("括弧付き", "からすのパンやさん", "かこさとし（作）"),
            ("文付き", "からすのパンやさん", "かこさとし文"),
            ("絵付き", "からすのパンやさん", "かこさとし絵"),
        ]

        print("\n=== 著者名役割語テスト ===")
        
        for variation in variations {
            do {
                let books = try await apiClient.searchBooks(
                    title: variation.title,
                    author: variation.author,
                    maxResults: 10
                )
                
                print("\n[\(variation.description)]")
                print("検索: 「\(variation.title)」「\(variation.author)」")
                print("結果: \(books.count)件")
                
                if !books.isEmpty {
                    print("トップ結果: \(books.first?.title ?? "不明") - \(books.first?.author ?? "不明")")
                }
            } catch {
                print("\n[\(variation.description)] - エラー: \(error)")
            }
        }
    }
    
    /// タイトルのみ vs タイトル+著者の比較
    @Test func testTitleOnlyVsTitleAuthor() async throws {
        let testBooks = [
            ("ぐりとぐら", "なかがわりえこ"),
            ("はらぺこあおむし", "エリック・カール"),
            ("100万回生きたねこ", "佐野洋子"),
        ]
        
        print("\n=== タイトルのみ vs タイトル+著者 比較 ===")
        
        for (title, author) in testBooks {
            print("\n--- \(title) ---")
            
            // タイトルのみ検索
            do {
                let titleOnlyBooks = try await apiClient.searchBooks(
                    title: title, author: nil, maxResults: 10)
                print("タイトルのみ: \(titleOnlyBooks.count)件")
                if let first = titleOnlyBooks.first {
                    print("  トップ: \(first.title) - \(first.author)")
                }
            } catch {
                print("タイトルのみ - エラー: \(error)")
            }
            
            // タイトル+著者検索
            do {
                let titleAuthorBooks = try await apiClient.searchBooks(
                    title: title, author: author, maxResults: 10)
                print("タイトル+著者: \(titleAuthorBooks.count)件")
                if let first = titleAuthorBooks.first {
                    print("  トップ: \(first.title) - \(first.author)")
                }
            } catch {
                print("タイトル+著者 - エラー: \(error)")
            }
        }
    }
}
