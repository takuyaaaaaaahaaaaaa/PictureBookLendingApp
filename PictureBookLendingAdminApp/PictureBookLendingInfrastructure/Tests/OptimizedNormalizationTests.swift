import Foundation
import PictureBookLendingDomain
import Testing

@testable import PictureBookLendingInfrastructure

/// 最適化された正規化の効果検証テスト
@Suite(.tags(.integrationTest))
struct OptimizedNormalizationTests {
    private let gateway = GoogleBookSearchGateway()
    private let originalNormalizer = JapaneseStringNormalizer()
    private let optimizedNormalizer = GoogleBooksOptimizedNormalizer()
    
    /// スペース問題の改善効果テスト
    @Test(.tags(.integrationTest)) func testSpaceNormalizationImprovement() async throws {
        print("=== スペース正規化の改善効果テスト ===")
        
        let testCases = [
            ("ぐり と ぐら", "なかがわりえこ", "ぐりとぐら"),
            ("ぐり　と　ぐら", "なかがわりえこ", "ぐりとぐら"),
            ("ぐり・と・ぐら", "なかがわりえこ", "ぐりとぐら"),
            ("はらぺこ あおむし", "エリック・カール", "はらぺこあおむし"),
            ("はらぺこ・あおむし", "エリック・カール", "はらぺこあおむし"),
            ("スイミー 小さなかしこいさかなのはなし", "レオ・レオニ", "スイミー"),
        ]
        
        var originalSuccessCount = 0
        var optimizedSuccessCount = 0
        
        for (title, author, expectedTitle) in testCases {
            print("\n--- タイトル: \"\(title)\" ---")
            
            // 元の正規化
            let originalNormalized = originalNormalizer.normalizeTitle(title)
            print("元の正規化: \"\(title)\" → \"\(originalNormalized)\"")
            
            // 最適化された正規化
            let optimizedNormalized = optimizedNormalizer.normalizeTitle(title)
            print("最適化正規化: \"\(title)\" → \"\(optimizedNormalized)\"")
            
            // 検索実行
            let originalResult = await searchBooks(title: originalNormalized, author: author)
            let optimizedResult = await searchBooks(title: optimizedNormalized, author: author)
            
            // 期待する結果が含まれているか確認
            let originalHasExpected = originalResult.books.contains {
                $0.title.contains(expectedTitle)
            }
            let optimizedHasExpected = optimizedResult.books.contains {
                $0.title.contains(expectedTitle)
            }
            
            if originalHasExpected { originalSuccessCount += 1 }
            if optimizedHasExpected { optimizedSuccessCount += 1 }
            
            print("\n結果:")
            print("  元の正規化: \(originalResult.count)件、期待結果: \(originalHasExpected ? "✅" : "❌")")
            print("  最適化正規化: \(optimizedResult.count)件、期待結果: \(optimizedHasExpected ? "✅" : "❌")")
            
            if !originalHasExpected && optimizedHasExpected {
                print("  🎉 最適化により検索可能になりました！")
            }
        }
        
        print("\n=== 統計 ===")
        print("元の正規化: \(originalSuccessCount)/\(testCases.count)件成功")
        print("最適化正規化: \(optimizedSuccessCount)/\(testCases.count)件成功")
        let improvement = optimizedSuccessCount - originalSuccessCount
        print("改善数: +\(improvement)件")
        
        #expect(optimizedSuccessCount > originalSuccessCount, "最適化により改善されるべき")
    }
    
    /// 著者名役割語の改善効果テスト
    @Test(.tags(.integrationTest)) func testAuthorRoleNormalizationImprovement() async throws {
        print("=== 著者名役割語の改善効果テスト ===")
        
        let testCases = [
            ("からすのパンやさん", "かこさとし作", "かこさとし"),
            ("からすのパンやさん", "かこさとし（作）", "かこさとし"),
            ("ぐりとぐら", "なかがわりえこ文", "なかがわりえこ"),
            ("ぐりとぐら", "なかがわ・りえこ", "なかがわりえこ"),
        ]
        
        var originalSuccessCount = 0
        var optimizedSuccessCount = 0
        
        for (title, author, expectedAuthor) in testCases {
            print("\n--- 著者: \"\(author)\" ---")
            
            // 正規化
            let originalAuthor = originalNormalizer.normalizeAuthor(author)
            let optimizedAuthor = optimizedNormalizer.normalizeAuthor(author)
            
            print("元の正規化: \"\(author)\" → \"\(originalAuthor)\"")
            print("最適化正規化: \"\(author)\" → \"\(optimizedAuthor)\"")
            
            // 検索実行
            let originalResult = await searchBooks(title: title, author: originalAuthor)
            let optimizedResult = await searchBooks(title: title, author: optimizedAuthor)
            
            // 期待する著者名が含まれているか確認
            let originalHasExpected = originalResult.books.contains {
                $0.author?.contains(expectedAuthor) ?? false
            }
            let optimizedHasExpected = optimizedResult.books.contains {
                $0.author?.contains(expectedAuthor) ?? false
            }
            
            if originalHasExpected { originalSuccessCount += 1 }
            if optimizedHasExpected { optimizedSuccessCount += 1 }
            
            print(
                "結果: 元=\(originalResult.count)件(\(originalHasExpected ? "✅" : "❌")), 最適化=\(optimizedResult.count)件(\(optimizedHasExpected ? "✅" : "❌"))"
            )
        }
        
        print("\n=== 統計 ===")
        print(
            "成功率: 元=\(originalSuccessCount)/\(testCases.count), 最適化=\(optimizedSuccessCount)/\(testCases.count)"
        )
    }
    
    /// 実際の利用シーンでの総合テスト
    @Test(.tags(.integrationTest)) func testRealWorldScenarios() async throws {
        print("=== 実際の利用シーンでの総合テスト ===")
        
        let scenarios = [
            ("手入力ミス", "ぐり　と　ぐら", "なかがわ　りえこ", "ぐりとぐら"),
            ("役割語付き", "はらぺこあおむし", "エリック・カール作", "はらぺこあおむし"),
            ("複雑なタイトル", "スイミー・小さなかしこいさかなのはなし", "レオ・レオニ", "スイミー"),
            ("数字変換", "１００万回生きたねこ", "佐野洋子", "100万回生きたねこ"),
        ]
        
        print("\n【検索クエリの変換】")
        for (_, title, author, _) in scenarios {
            let optTitle = optimizedNormalizer.normalizeTitle(title)
            let optAuthor = optimizedNormalizer.normalizeAuthor(author)
            print("入力: \"\(title)\" by \"\(author)\"")
            print("  → \"\(optTitle)\" by \"\(optAuthor)\"")
        }
        
        var successCount = 0
        
        print("\n【検索結果】")
        for (scenario, title, author, expectedInTitle) in scenarios {
            print("\n\(scenario):")
            
            let normalizedTitle = optimizedNormalizer.normalizeTitle(title)
            let normalizedAuthor = optimizedNormalizer.normalizeAuthor(author)
            
            let result = await searchBooks(title: normalizedTitle, author: normalizedAuthor)
            let hasExpected = result.books.contains { $0.title.contains(expectedInTitle) }
            
            if hasExpected { successCount += 1 }
            
            print("  結果: \(result.count)件、期待タイトル含む: \(hasExpected ? "✅" : "❌")")
            if result.count > 0 {
                print("  トップ結果: \(result.books.first?.title ?? "不明")")
            }
        }
        
        let successRate = Double(successCount) / Double(scenarios.count) * 100
        print(
            "\n総合成功率: \(successCount)/\(scenarios.count) (\(String(format: "%.0f", successRate))%)")
        
        #expect(successCount >= 3, "少なくとも75%以上の成功率が期待される")
    }
    
    // MARK: - Helper
    
    private func searchBooks(title: String, author: String?) async -> (count: Int, books: [Book]) {
        do {
            let books = try await gateway.searchBooks(
                title: title,
                author: author,
                maxResults: 10
            )
            return (books.count, books)
        } catch {
            return (0, [])
        }
    }
}
