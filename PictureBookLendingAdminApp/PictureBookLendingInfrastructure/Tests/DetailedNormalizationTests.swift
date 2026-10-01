import Foundation
import PictureBookLendingDomain
import Testing

@testable import PictureBookLendingInfrastructure

/// 詳細な正規化効果検証テスト
@Suite(.tags(.integrationTest), .liveAPITest)
struct DetailedNormalizationTests {
    private let gateway = GoogleBookSearchGateway()
    private let normalizer = JapaneseStringNormalizer()
    
    /// スペース正規化の詳細テスト
    @Test(.tags(.integrationTest)) func testSpaceNormalizationDetail() async throws {
        print("=== スペース正規化の詳細テスト ===")
        
        let _ = "ぐりとぐら"  // 基準となる絵本タイトル
        let author = "なかがわりえこ"
        
        // さまざまなスペースパターン
        let spacePatterns = [
            ("正常", "ぐりとぐら"),
            ("半角スペース", "ぐり と ぐら"),
            ("全角スペース", "ぐり　と　ぐら"),
            ("複数半角スペース", "ぐり  と  ぐら"),
            ("複数全角スペース", "ぐり　　と　　ぐら"),
            ("混在スペース", "ぐり 　と　 ぐら"),
            ("タブ文字", "ぐり\tと\tぐら"),
        ]
        
        for (description, title) in spacePatterns {
            print("\n--- \(description): \"\(title)\" ---")
            
            // 正規化前
            do {
                let books = try await gateway.searchBooks(
                    title: title,
                    author: author,
                    maxResults: 5
                )
                print("【正規化なし】")
                print("  結果数: \(books.count)件")
                if books.count > 0 {
                    print("  トップ3:")
                    for (i, book) in books.prefix(3).enumerated() {
                        print("    \(i+1). \(book.title)")
                    }
                }
            } catch {
                print("【正規化なし】エラー: \(error)")
            }
            
            // 正規化後
            let normalizedTitle = normalizer.normalizeTitle(title)
            print("\n  正規化: \"\(title)\" → \"\(normalizedTitle)\"")
            
            do {
                let books = try await gateway.searchBooks(
                    title: normalizedTitle,
                    author: author,
                    maxResults: 5
                )
                print("【正規化あり】")
                print("  結果数: \(books.count)件")
                if books.count > 0 {
                    print("  トップ3:")
                    for (i, book) in books.prefix(3).enumerated() {
                        print("    \(i+1). \(book.title)")
                    }
                }
            } catch {
                print("【正規化あり】エラー: \(error)")
            }
        }
    }
    
    /// 記号正規化の詳細テスト
    @Test(.tags(.integrationTest)) func testSymbolNormalizationDetail() async throws {
        print("=== 記号正規化の詳細テスト ===")
        
        let author = "エリック・カール"
        
        // さまざまな記号パターン
        let symbolPatterns = [
            ("正常", "はらぺこあおむし"),
            ("中黒", "はらぺこ・あおむし"),
            ("複数中黒", "はら・ぺこ・あおむし"),
            ("ハイフン", "はらぺこ-あおむし"),
            ("長音符", "はらぺこ―あおむし"),
            ("波ダッシュ", "はらぺこ〜あおむし"),
            ("読点", "はらぺこ、あおむし"),
        ]
        
        for (description, title) in symbolPatterns {
            print("\n--- \(description): \"\(title)\" ---")
            
            // 正規化前後の結果を取得
            let originalResult = await getSearchResult(title: title, author: author)
            let normalizedTitle = normalizer.normalizeTitle(title)
            let normalizedResult = await getSearchResult(title: normalizedTitle, author: author)
            
            print("正規化: \"\(title)\" → \"\(normalizedTitle)\"")
            print(
                "【正規化なし】結果: \(originalResult.count)件, 期待含む: \(originalResult.hasExpected ? "✅" : "❌")"
            )
            print(
                "【正規化あり】結果: \(normalizedResult.count)件, 期待含む: \(normalizedResult.hasExpected ? "✅" : "❌")"
            )
            
            if originalResult.count == 0 && normalizedResult.count > 0 {
                print("🎉 正規化により検索可能になりました！")
            }
        }
    }
    
    /// 著者名正規化の詳細テスト
    @Test(.tags(.integrationTest)) func testAuthorNormalizationDetail() async throws {
        print("=== 著者名正規化の詳細テスト ===")
        
        let title = "ぐりとぐら"
        
        // さまざまな著者名パターン
        let authorPatterns = [
            ("正常", "なかがわりえこ"),
            ("スペース入り", "なかがわ りえこ"),
            ("中黒入り", "なかがわ・りえこ"),
            ("漢字", "中川李枝子"),
            ("役割語付き", "なかがわりえこ作"),
            ("括弧役割語", "なかがわりえこ（作）"),
            ("複合役割語", "なかがわりえこ 作・絵"),
        ]
        
        for (description, author) in authorPatterns {
            print("\n--- \(description): \"\(author)\" ---")
            
            let normalizedAuthor = normalizer.normalizeAuthor(author)
            print("正規化: \"\(author)\" → \"\(normalizedAuthor)\"")
            
            // 正規化前
            let originalResult = await getSearchResult(title: title, author: author)
            // 正規化後
            let normalizedResult = await getSearchResult(title: title, author: normalizedAuthor)
            
            print("【正規化なし】結果: \(originalResult.count)件")
            print("【正規化あり】結果: \(normalizedResult.count)件")
            
            if originalResult.count < normalizedResult.count {
                print("📈 正規化により \(normalizedResult.count - originalResult.count)件増加")
            }
        }
    }
    
    /// 実際の絵本タイトルでの総合テスト
    @Test(.tags(.integrationTest)) func testRealBookTitlesComprehensive() async throws {
        print("=== 実際の絵本タイトルでの総合テスト ===")
        
        let realBookTests = [
            ("スペース問題", "ぐり と ぐら", "なかがわりえこ", "ぐりとぐら"),
            ("役割語問題", "はらぺこあおむし", "エリック・カール作", "はらぺこあおむし"),
            ("記号問題", "スイミー・小さなかしこいさかなのはなし", "レオ・レオニ", "スイミー"),
            ("数字問題", "１００万回生きたねこ", "佐野洋子", "100万回生きたねこ"),
        ]
        
        var totalImproved = 0
        
        for (issue, title, author, expectedInTitle) in realBookTests {
            print("\n--- \(issue) ---")
            print("入力: タイトル=\"\(title)\", 著者=\"\(author)\"")
            
            // 正規化
            let normalizedTitle = normalizer.normalizeTitle(title)
            let normalizedAuthor = normalizer.normalizeAuthor(author)
            print("正規化後: タイトル=\"\(normalizedTitle)\", 著者=\"\(normalizedAuthor)\"")
            
            // 検索実行
            let originalResult = await getSearchResult(title: title, author: author)
            let normalizedResult = await getSearchResult(
                title: normalizedTitle, author: normalizedAuthor)
            
            // 期待する結果が含まれているか確認
            let originalHasExpected = originalResult.books.contains {
                $0.title.contains(expectedInTitle)
            }
            let normalizedHasExpected = normalizedResult.books.contains {
                $0.title.contains(expectedInTitle)
            }
            
            print("\n結果:")
            print("  正規化なし: \(originalResult.count)件、期待結果: \(originalHasExpected ? "✅" : "❌")")
            print("  正規化あり: \(normalizedResult.count)件、期待結果: \(normalizedHasExpected ? "✅" : "❌")")
            
            if !originalHasExpected && normalizedHasExpected {
                print("  🎉 正規化により期待する結果が得られました！")
                totalImproved += 1
            }
        }
        
        print("\n=== 総合結果 ===")
        print("改善されたケース: \(totalImproved)/\(realBookTests.count)件")
        let improvementRate = Double(totalImproved) / Double(realBookTests.count) * 100
        print("改善率: \(String(format: "%.0f", improvementRate))%")
    }
    
    // MARK: - Helper
    
    private func getSearchResult(title: String, author: String?) async -> (
        count: Int, hasExpected: Bool, books: [Book]
    ) {
        do {
            let books = try await gateway.searchBooks(
                title: title,
                author: author,
                maxResults: 10
            )
            return (books.count, !books.isEmpty, books)
        } catch {
            return (0, false, [])
        }
    }
}
