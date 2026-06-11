import PictureBookLendingDomain
import Testing

@testable import PictureBookLendingInfrastructure

struct JapaneseStringNormalizerTests {
    let normalizer = JapaneseStringNormalizer()
    
    // MARK: - 基本的な正規化テスト
    
    @Test func testNormalizeSpaces() {
        // 全角スペースを半角に
        #expect(normalizer.normalize("ぐり　と　ぐら") == "ぐり と ぐら")
        
        // 複数の連続スペースを1つに
        #expect(normalizer.normalize("ぐり  と  ぐら") == "ぐり と ぐら")
        
        // 前後の空白を削除
        #expect(normalizer.normalize("  ぐりとぐら  ") == "ぐりとぐら")
    }
    
    @Test func testNormalizeFullWidthCharacters() {
        // 全角英数字を半角に
        #expect(normalizer.normalize("ＡＢＣ１２３") == "ABC123")
        #expect(normalizer.normalize("はらぺこあおむし２") == "はらぺこあおむし2")
    }
    
    @Test func testNormalizeSymbols() {
        // 中黒をスペースに
        #expect(normalizer.normalize("なかがわ・りえこ") == "なかがわ りえこ")
        #expect(normalizer.normalize("なかがわ･りえこ") == "なかがわ りえこ")
        
        // ハイフン類を統一
        #expect(normalizer.normalize("はらぺこ－あおむし") == "はらぺこ-あおむし")
        #expect(normalizer.normalize("はらぺこ—あおむし") == "はらぺこ-あおむし")
        #expect(normalizer.normalize("はらぺこ―あおむし") == "はらぺこ-あおむし")
        
        // 括弧を半角に
        #expect(normalizer.normalize("ぐりとぐら（絵本）") == "ぐりとぐら(絵本)")
    }
    
    @Test func testNormalizeVariantCharacters() {
        // 旧字体・異体字を正規化
        #expect(normalizer.normalize("髙橋") == "高橋")
        #expect(normalizer.normalize("﨑山") == "崎山")
        #expect(normalizer.normalize("德川") == "徳川")
    }
    
    // MARK: - タイトル正規化テスト
    
    @Test func testNormalizeTitleComplexCases() {
        // 複合的なケース
        #expect(normalizer.normalizeTitle("ぐり　と　ぐら　（絵本）") == "ぐり と ぐら (絵本)")
        #expect(normalizer.normalizeTitle("　はらぺこ・あおむし２　") == "はらぺこ あおむし2")
        #expect(normalizer.normalizeTitle("１００万回生きたねこ") == "100万回生きたねこ")
    }
    
    // MARK: - 著者名正規化テスト
    
    @Test func testNormalizeAuthorRemoveRoles() {
        // 役割語の削除
        #expect(normalizer.normalizeAuthor("宮沢賢治作") == "宮沢賢治")
        #expect(normalizer.normalizeAuthor("なかがわりえこ さく") == "なかがわりえこ")
        #expect(normalizer.normalizeAuthor("エリック・カール 絵") == "エリック カール")
        
        // 括弧内の役割語を削除
        #expect(normalizer.normalizeAuthor("宮沢賢治（作）") == "宮沢賢治")
        #expect(normalizer.normalizeAuthor("なかがわ りえこ（文）") == "なかがわ りえこ")
        #expect(normalizer.normalizeAuthor("エリック・カール（絵）") == "エリック カール")
    }
    
    @Test func testNormalizeAuthorComplexCases() {
        // 複合的なケース
        #expect(normalizer.normalizeAuthor("なかがわ・りえこ（作）") == "なかがわ りえこ")
        #expect(normalizer.normalizeAuthor("　宮沢　賢治　著　") == "宮沢 賢治")
        #expect(normalizer.normalizeAuthor("ＬｅｏＬｉｏｎｎｉ") == "LeoLionni")
    }
    
    // MARK: - エッジケーステスト
    
    @Test func testEdgeCases() {
        // 空文字列
        #expect(normalizer.normalize("") == "")
        #expect(normalizer.normalize("   ") == "")
        
        // 記号のみ
        #expect(normalizer.normalize("・・・") == "")
        #expect(normalizer.normalize("　　　") == "")
        
        // 特殊なケース
        #expect(normalizer.normalize("ぐり・と・ぐら") == "ぐり と ぐら")
        #expect(normalizer.normalize("ぐり　・　と　・　ぐら") == "ぐり と ぐら")
    }
    
    // MARK: - 実際の絵本タイトルでのテスト
    
    @Test func testRealBookTitles() {
        // 有名な絵本のタイトル
        let testCases: [(input: String, expected: String)] = [
            ("ぐり　と　ぐら", "ぐり と ぐら"),
            ("はらぺこ・あおむし", "はらぺこ あおむし"),
            ("１００万回生きたねこ", "100万回生きたねこ"),
            ("スイミー―小さなかしこいさかなのはなし", "スイミー-小さなかしこいさかなのはなし"),
            ("かいじゅうたちのいるところ", "かいじゅうたちのいるところ"),
            ("ねないこ　だれだ", "ねないこ だれだ"),
        ]

        for (input, expected) in testCases {
            #expect(normalizer.normalizeTitle(input) == expected)
        }
    }
    
    @Test func testRealAuthorNames() {
        // 有名な絵本作家の名前
        let testCases: [(input: String, expected: String)] = [
            ("なかがわ・りえこ", "なかがわ りえこ"),
            ("エリック・カール", "エリック カール"),
            ("レオ・レオニ", "レオ レオニ"),
            ("宮沢　賢治", "宮沢 賢治"),
            ("せな　けいこ", "せな けいこ"),
            ("モーリス・センダック", "モーリス センダック"),
        ]

        for (input, expected) in testCases {
            #expect(normalizer.normalizeAuthor(input) == expected)
        }
    }
}
