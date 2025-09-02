//
//  BookSectionState+sorted.swift
//  PictureBookLendingAdmin
//
//  Created by takuya_tominaga on 8/29/25.
//

import Observation
import PictureBookLendingDomain
import PictureBookLendingUI
import SwiftUI

/// グループ単位のBookオブジェクトを管理するState
@Observable
class BookSectionsState {
    /// /// 五十音順グループごとの絵本分類
    private var bookSections: [BookSection] = []
    
    init(books: [Book]) {
        self.bookSections = createSections(from: books)
    }
    
    /// フィルタリング・ソート済みの絵本セクション
    public func filter(
        searchText: String, kanafilter: KanaGroup?, sortType: BookSortType
    ) -> [BookSection] {
        // 1. フィルタリング
        let filteredSections = filtered(
            sections: bookSections,
            searchText: searchText,
            selectedKanaFilter: kanafilter
        )
        
        // 2. ソート
        return sorted(sections: filteredSections, by: sortType)
    }
    
    /// 全絵本からBookSectionの配列を作成
    private func createSections(from books: [Book]) -> [BookSection] {
        // 五十音グループごとに分類
        let groupedBooks = Dictionary(grouping: books) { book -> KanaGroup in
            return book.kanaGroup ?? .other
        }
        
        // セクションを作成
        let sections = groupedBooks.map { (kanaGroup, books) in
            BookSection(kanaGroup: kanaGroup, books: books)
        }
        
        // 五十音順にソート
        return sections.sorted { $0.kanaGroup.sortOrder < $1.kanaGroup.sortOrder }
    }
    
    /// 検索テキストとかなフィルターでセクション配列をフィルタリング
    private func filtered(
        sections: [BookSection],
        searchText: String,
        selectedKanaFilter: KanaGroup?
    ) -> [BookSection] {
        var filteredSections = sections
        
        // 検索テキストでフィルタリング
        if !searchText.isEmpty {
            filteredSections = filteredSections.compactMap { section in
                let filteredBooks = section.books.filter { book in
                    book.title.localizedCaseInsensitiveContains(searchText)
                        || book.author?.localizedCaseInsensitiveContains(searchText) == true
                }
                return filteredBooks.isEmpty
                    ? nil : BookSection(kanaGroup: section.kanaGroup, books: filteredBooks)
            }
        }
        
        // 選択されたフィルターがある場合は該当セクションのみ表示
        if let selectedKanaFilter = selectedKanaFilter {
            filteredSections = filteredSections.filter { $0.kanaGroup == selectedKanaFilter }
        }
        
        return filteredSections
    }
    
    /// ソート方法に基づいてセクション配列をソート
    private func sorted(sections: [BookSection], by sortType: BookSortType) -> [BookSection] {
        return sections.map { section in
            let sortedBooks: [Book]
            switch sortType {
            case .title:
                sortedBooks = section.books.sorted { $0.title < $1.title }
            case .managementNumber:
                sortedBooks = section.books.sorted { book1, book2 in
                    switch (book1.managementNumber, book2.managementNumber) {
                    case (nil, nil):
                        return book1.title < book2.title
                    // 管理番号がない場合は最後に配置
                    case (nil, _):
                        return false
                    case (_, nil):
                        return true
                    case (let managementNumber1?, let managementNumber2?):
                        // ひらがな順 > 数字順
                        let key1 = sortKey(managementNumber1)
                        let key2 = sortKey(managementNumber2)
                        if key1.hiragana == key2.hiragana {
                            return key1.number < key2.number
                        } else {
                            return key1.hiragana < key2.hiragana
                        }
                    }
                }
            }
            return BookSection(kanaGroup: section.kanaGroup, books: sortedBooks)
        }
    }
}

/// 管理番号のソート用キーを作成
/// "文字列数字文字列"パターンに対応（例: "abc123def", "あ001-a"）
/// 全角数字と半角数字の両方に対応
private func sortKey(_ text: String) -> (hiragana: String, number: Int) {
    let normalizedText = normalizeNumbers(text)
    
    // 最初の数字列を見つける
    var stringPrefix = ""
    var numberString = ""
    var foundNumber = false
    
    for char in normalizedText {
        if char.isNumber {
            if !foundNumber {
                foundNumber = true
            }
            numberString.append(char)
        } else {
            if foundNumber {
                // 数字の後の文字が来たら数字部分の抽出完了
                break
            } else {
                // まだ数字が見つかってない場合は文字列部分
                stringPrefix.append(char)
            }
        }
    }
    
    // 文字列部分が空の場合は元のテキストを使用
    let prefix = stringPrefix.isEmpty ? text : stringPrefix
    let number = Int(numberString) ?? 0
    
    return (prefix, number)
}

/// 全角数字を半角数字に変換
private func normalizeNumbers(_ text: String) -> String {
    let fullWidthNumbers = "０１２３４５６７８９"
    let halfWidthNumbers = "0123456789"
    
    var result = text
    for (fullWidth, halfWidth) in zip(fullWidthNumbers, halfWidthNumbers) {
        result = result.replacingOccurrences(of: String(fullWidth), with: String(halfWidth))
    }
    return result
}
