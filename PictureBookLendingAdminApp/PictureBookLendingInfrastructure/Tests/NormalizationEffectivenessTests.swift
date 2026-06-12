import Foundation
import PictureBookLendingDomain
import Testing

@testable import PictureBookLendingInfrastructure

/// 正規化効果検証テスト - 正規化前後での検索精度を比較
@Suite(.tags(.integrationTest), .liveAPITest)
struct NormalizationEffectivenessTests {
    private let gateway = GoogleBookSearchGateway()
    private let normalizer = JapaneseStringNormalizer()
    
    /// テスト結果を記録する構造体
    struct SearchResult {
        let query: String
        let normalizedQuery: String
        let resultCount: Int
        let topResult: String?
        let hasExpectedResult: Bool
    }
    
    /// 「ぐりとぐら」の正規化効果テスト
    @Test(.tags(.integrationTest)) func testGuriToGuraNormalizationEffect() async throws {
        let testCases:
            [(description: String, title: String, author: String?, expectedTitle: String)] = [
                ("基本形", "ぐりとぐら", "なかがわりえこ", "ぐりとぐら"),
                ("スペース入り", "ぐり と ぐら", "なかがわりえこ", "ぐりとぐら"),
                ("全角スペース", "ぐり　と　ぐら", "なかがわりえこ", "ぐりとぐら"),
                ("中黒区切り", "ぐり・と・ぐら", "なかがわりえこ", "ぐりとぐら"),
                ("著者中黒", "ぐりとぐら", "なかがわ・りえこ", "ぐりとぐら"),
                ("著者スペース", "ぐりとぐら", "なかがわ りえこ", "ぐりとぐら"),
            ]

        print("=== 「ぐりとぐら」正規化効果テスト ===")
        print("期待タイトル: ぐりとぐら")
        
        var results: [(original: SearchResult, normalized: SearchResult)] = []
        
        for testCase in testCases {
            print("\n--- \(testCase.description) ---")
            
            // 正規化なしで検索
            let originalResult = await searchWithoutNormalization(
                title: testCase.title,
                author: testCase.author,
                expectedTitle: testCase.expectedTitle
            )
            
            // 正規化ありで検索
            let normalizedResult = await searchWithNormalization(
                title: testCase.title,
                author: testCase.author,
                expectedTitle: testCase.expectedTitle
            )
            
            results.append((original: originalResult, normalized: normalizedResult))
            
            // 結果を比較表示
            print("\n【正規化なし】")
            print("  クエリ: タイトル=\"\(originalResult.query)\"")
            print("  結果数: \(originalResult.resultCount)件")
            print("  トップ結果: \(originalResult.topResult ?? "なし")")
            print("  期待結果含む: \(originalResult.hasExpectedResult ? "✅" : "❌")")
            
            print("\n【正規化あり】")
            print(
                "  クエリ: タイトル=\"\(normalizedResult.query)\" → \"\(normalizedResult.normalizedQuery)\""
            )
            print("  結果数: \(normalizedResult.resultCount)件")
            print("  トップ結果: \(normalizedResult.topResult ?? "なし")")
            print("  期待結果含む: \(normalizedResult.hasExpectedResult ? "✅" : "❌")")
            
            // 改善度を計算
            if originalResult.resultCount > 0 || normalizedResult.resultCount > 0 {
                let improvement =
                    normalizedResult.hasExpectedResult && !originalResult.hasExpectedResult
                print("  改善: \(improvement ? "🎉 正規化により期待結果が得られた" : "変化なし")")
            }
        }
        
        // 全体の統計
        printStatistics(results: results)
    }
    
    /// 「はらぺこあおむし」の正規化効果テスト
    @Test(.tags(.integrationTest)) func testHungryBugNormalizationEffect() async throws {
        let testCases:
            [(description: String, title: String, author: String?, expectedTitle: String)] = [
                ("基本形", "はらぺこあおむし", "エリック・カール", "はらぺこあおむし"),
                ("スペース入り", "はらぺこ あおむし", "エリック・カール", "はらぺこあおむし"),
                ("中黒区切り", "はらぺこ・あおむし", "エリック・カール", "はらぺこあおむし"),
                ("著者中黒", "はらぺこあおむし", "エリック・カール", "はらぺこあおむし"),
                ("著者スペース", "はらぺこあおむし", "エリック カール", "はらぺこあおむし"),
            ]

        print("\n=== 「はらぺこあおむし」正規化効果テスト ===")
        print("期待タイトル: はらぺこあおむし")
        
        var results: [(original: SearchResult, normalized: SearchResult)] = []
        
        for testCase in testCases {
            print("\n--- \(testCase.description) ---")
            
            let originalResult = await searchWithoutNormalization(
                title: testCase.title,
                author: testCase.author,
                expectedTitle: testCase.expectedTitle
            )
            
            let normalizedResult = await searchWithNormalization(
                title: testCase.title,
                author: testCase.author,
                expectedTitle: testCase.expectedTitle
            )
            
            results.append((original: originalResult, normalized: normalizedResult))
            
            // 結果を比較表示
            print("\n【正規化なし】")
            print("  結果数: \(originalResult.resultCount)件")
            print("  期待結果含む: \(originalResult.hasExpectedResult ? "✅" : "❌")")
            
            print("\n【正規化あり】")
            print("  結果数: \(normalizedResult.resultCount)件")
            print("  期待結果含む: \(normalizedResult.hasExpectedResult ? "✅" : "❌")")
        }
        
        printStatistics(results: results)
    }
    
    /// 数字・記号の正規化効果テスト
    @Test(.tags(.integrationTest)) func testNumberAndSymbolNormalizationEffect() async throws {
        let testCases:
            [(description: String, title: String, author: String, expectedTitle: String)] = [
                ("数字半角", "100万回生きたねこ", "佐野洋子", "100万回生きたねこ"),
                ("数字全角", "１００万回生きたねこ", "佐野洋子", "100万回生きたねこ"),
                ("数字漢数字", "百万回生きたねこ", "佐野洋子", "100万回生きたねこ"),
            ]

        print("\n=== 数字・記号の正規化効果テスト ===")
        
        var results: [(original: SearchResult, normalized: SearchResult)] = []
        
        for testCase in testCases {
            print("\n--- \(testCase.description) ---")
            
            let originalResult = await searchWithoutNormalization(
                title: testCase.title,
                author: testCase.author,
                expectedTitle: testCase.expectedTitle
            )
            
            let normalizedResult = await searchWithNormalization(
                title: testCase.title,
                author: testCase.author,
                expectedTitle: testCase.expectedTitle
            )
            
            results.append((original: originalResult, normalized: normalizedResult))
            
            print(
                "【正規化なし】結果数: \(originalResult.resultCount)件, 期待結果: \(originalResult.hasExpectedResult ? "✅" : "❌")"
            )
            print(
                "【正規化あり】結果数: \(normalizedResult.resultCount)件, 期待結果: \(normalizedResult.hasExpectedResult ? "✅" : "❌")"
            )
        }
        
        printStatistics(results: results)
    }
    
    /// 著者名役割語の正規化効果テスト
    @Test(.tags(.integrationTest)) func testAuthorRoleNormalizationEffect() async throws {
        let testCases:
            [(description: String, title: String, author: String, expectedTitle: String)] = [
                ("著者名のみ", "からすのパンやさん", "かこさとし", "からすのパンやさん"),
                ("作者付き", "からすのパンやさん", "かこさとし作", "からすのパンやさん"),
                ("括弧付き", "からすのパンやさん", "かこさとし（作）", "からすのパンやさん"),
                ("文付き", "からすのパンやさん", "かこさとし文", "からすのパンやさん"),
                ("絵付き", "からすのパンやさん", "かこさとし絵", "からすのパンやさん"),
            ]

        print("\n=== 著者名役割語の正規化効果テスト ===")
        
        var results: [(original: SearchResult, normalized: SearchResult)] = []
        
        for testCase in testCases {
            print("\n--- \(testCase.description) ---")
            
            let originalResult = await searchWithoutNormalization(
                title: testCase.title,
                author: testCase.author,
                expectedTitle: testCase.expectedTitle
            )
            
            let normalizedResult = await searchWithNormalization(
                title: testCase.title,
                author: testCase.author,
                expectedTitle: testCase.expectedTitle
            )
            
            results.append((original: originalResult, normalized: normalizedResult))
            
            print(
                "【正規化なし】著者=\"\(testCase.author)\", 結果: \(originalResult.resultCount)件, 期待結果: \(originalResult.hasExpectedResult ? "✅" : "❌")"
            )
            print(
                "【正規化あり】著者=\"\(normalizedResult.normalizedQuery)\", 結果: \(normalizedResult.resultCount)件, 期待結果: \(normalizedResult.hasExpectedResult ? "✅" : "❌")"
            )
        }
        
        printStatistics(results: results)
    }
    
    // MARK: - Helper Methods
    
    /// 正規化なしで検索
    private func searchWithoutNormalization(title: String, author: String?, expectedTitle: String)
        async -> SearchResult
    {
        do {
            let books = try await gateway.searchBooks(
                title: title,
                author: author,
                maxResults: 10
            )
            
            let hasExpected = books.contains { book in
                book.title.contains(expectedTitle)
            }
            
            return SearchResult(
                query: "\(title), \(author ?? "著者なし")",
                normalizedQuery: "",
                resultCount: books.count,
                topResult: books.first?.title,
                hasExpectedResult: hasExpected
            )
        } catch {
            return SearchResult(
                query: "\(title), \(author ?? "著者なし")",
                normalizedQuery: "",
                resultCount: 0,
                topResult: nil,
                hasExpectedResult: false
            )
        }
    }
    
    /// 正規化ありで検索
    private func searchWithNormalization(title: String, author: String?, expectedTitle: String)
        async -> SearchResult
    {
        let normalizedTitle = normalizer.normalizeTitle(title)
        let normalizedAuthor = author.map { normalizer.normalizeAuthor($0) }
        
        do {
            let books = try await gateway.searchBooks(
                title: normalizedTitle,
                author: normalizedAuthor,
                maxResults: 10
            )
            
            let hasExpected = books.contains { book in
                book.title.contains(expectedTitle)
            }
            
            return SearchResult(
                query: "\(title), \(author ?? "著者なし")",
                normalizedQuery: "\(normalizedTitle), \(normalizedAuthor ?? "著者なし")",
                resultCount: books.count,
                topResult: books.first?.title,
                hasExpectedResult: hasExpected
            )
        } catch {
            return SearchResult(
                query: "\(title), \(author ?? "著者なし")",
                normalizedQuery: "\(normalizedTitle), \(normalizedAuthor ?? "著者なし")",
                resultCount: 0,
                topResult: nil,
                hasExpectedResult: false
            )
        }
    }
    
    /// 統計情報を出力
    private func printStatistics(results: [(original: SearchResult, normalized: SearchResult)]) {
        print("\n=== 統計情報 ===")
        
        let totalTests = results.count
        var improvedCount = 0
        var degradedCount = 0
        var noChangeCount = 0
        
        for (original, normalized) in results {
            if !original.hasExpectedResult && normalized.hasExpectedResult {
                improvedCount += 1
            } else if original.hasExpectedResult && !normalized.hasExpectedResult {
                degradedCount += 1
            } else {
                noChangeCount += 1
            }
        }
        
        let improvementRate = Double(improvedCount) / Double(totalTests) * 100
        
        print("総テスト数: \(totalTests)")
        print("改善: \(improvedCount)件 (\(String(format: "%.1f", improvementRate))%)")
        print("劣化: \(degradedCount)件")
        print("変化なし: \(noChangeCount)件")
        
        // 正規化前後の成功率
        let originalSuccessCount = results.filter { $0.original.hasExpectedResult }.count
        let normalizedSuccessCount = results.filter { $0.normalized.hasExpectedResult }.count
        
        let originalSuccessRate = Double(originalSuccessCount) / Double(totalTests) * 100
        let normalizedSuccessRate = Double(normalizedSuccessCount) / Double(totalTests) * 100
        
        print("\n成功率:")
        print(
            "  正規化なし: \(originalSuccessCount)/\(totalTests) (\(String(format: "%.1f", originalSuccessRate))%)"
        )
        print(
            "  正規化あり: \(normalizedSuccessCount)/\(totalTests) (\(String(format: "%.1f", normalizedSuccessRate))%)"
        )
        print("  改善度: +\(String(format: "%.1f", normalizedSuccessRate - originalSuccessRate))%")
    }
}
