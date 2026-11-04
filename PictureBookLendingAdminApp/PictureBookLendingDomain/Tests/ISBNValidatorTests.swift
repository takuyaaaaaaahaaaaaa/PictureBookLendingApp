import Testing

@testable import PictureBookLendingDomain

/// ISBNValidatorテストケース
@Suite("ISBNValidator Tests")
struct ISBNValidatorTests {

    // MARK: - normalize

    @Test("ハイフン除去・大文字化・前後空白除去を行う")
    func normalizeRemovesHyphensAndUppercases() {
        #expect(ISBNValidator.normalize(" 0-8044-2957-x \n") == "080442957X")
    }

    // MARK: - ISBN-13

    @Test("有効なISBN-13（978始まり）は通る")
    func validISBN13With978() {
        #expect(ISBNValidator.isValidISBN13("9780306406157"))
    }

    @Test("有効なISBN-13（979始まり）は通る")
    func validISBN13With979() {
        #expect(ISBNValidator.isValidISBN13("9791090636071"))
    }

    @Test("ハイフン付きでも検証できる")
    func validISBN13WithHyphens() {
        #expect(ISBNValidator.isValidISBN13("978-0-306-40615-7"))
    }

    @Test("チェックディジットが違うISBN-13は通らない")
    func invalidChecksumISBN13() {
        #expect(!ISBNValidator.isValidISBN13("9780306406158"))
    }

    @Test("隣り合う桁を入れ替えたISBN-13は通らない（重みの検証）")
    func transposedISBN13() {
        // 9780306406157 の 4桁目と5桁目(0,3)を入れ替え
        #expect(!ISBNValidator.isValidISBN13("9783006406157"))
    }

    @Test("978/979以外のプレフィックスは通らない")
    func invalidPrefixISBN13() {
        // チェックディジットは正しいが、先頭が977（978/979以外）の値
        #expect(!ISBNValidator.isValidISBN13("9770306406158"))
    }

    @Test("桁数が違う・数字以外を含むISBN-13は通らない")
    func malformedISBN13() {
        #expect(!ISBNValidator.isValidISBN13("978030640615"))
        #expect(!ISBNValidator.isValidISBN13("97803064061570"))
        #expect(!ISBNValidator.isValidISBN13("978030640615X"))
    }

    // MARK: - ISBN-10

    @Test("有効なISBN-10は通る")
    func validISBN10() {
        #expect(ISBNValidator.isValidISBN10("0306406152"))
    }

    @Test("末尾Xのチェックディジット（10）を持つISBN-10は通る")
    func validISBN10WithX() {
        #expect(ISBNValidator.isValidISBN10("080442957X"))
        #expect(ISBNValidator.isValidISBN10("0-8044-2957-x"))
    }

    @Test("チェックディジットが違うISBN-10は通らない")
    func invalidChecksumISBN10() {
        #expect(!ISBNValidator.isValidISBN10("0306406153"))
    }

    @Test("Xが末尾以外にあるISBN-10は通らない")
    func misplacedXISBN10() {
        #expect(!ISBNValidator.isValidISBN10("0X06406152"))
    }

    @Test("桁数が違うISBN-10は通らない")
    func wrongLengthISBN10() {
        #expect(!ISBNValidator.isValidISBN10("030640615"))
    }

    // MARK: - isValidISBN

    @Test("ISBN-10とISBN-13のどちらでも有効と判定し、不正は弾く")
    func isValidISBNAcceptsEither() {
        #expect(ISBNValidator.isValidISBN("0306406152"))
        #expect(ISBNValidator.isValidISBN("9780306406157"))
        #expect(!ISBNValidator.isValidISBN("1234567890123"))
        #expect(!ISBNValidator.isValidISBN(""))
    }
}
