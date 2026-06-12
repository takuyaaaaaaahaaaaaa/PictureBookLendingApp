//
//  Migration.swift
//  PictureBookLendingAdmin
//
//  Created by takuya_tominaga on 8/28/25.
//

import Foundation
import SwiftData

struct PictureBookLendingSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }
    static var models: [any PersistentModel.Type] {
        [
            SwiftDataLoan.self,
            SwiftDataBook.self,
            SwiftDataUser.self,
            SwiftDataClassGroup.self,
        ]
    }
    @Model
    final public class SwiftDataLoan {
        @Attribute(.unique) public var id: UUID
        public var bookId: UUID
        public var user: User
        public var loanDate: Date
        public var dueDate: Date
        public var returnedDate: Date?
        public init(
            id: UUID,
            bookId: UUID,
            user: User,
            loanDate: Date,
            dueDate: Date,
            returnedDate: Date? = nil
        ) {
            self.id = id
            self.bookId = bookId
            self.user = user
            self.loanDate = loanDate
            self.dueDate = dueDate
            self.returnedDate = returnedDate
        }
    }
    
    @Model
    final public class SwiftDataUser {
        @Attribute(.unique) public var id: UUID
        public var name: String
        public var classGroupId: UUID
        init(id: UUID, name: String, classGroupId: UUID) {
            self.id = id
            self.name = name
            self.classGroupId = classGroupId
        }
    }
    
    @Model
    final public class SwiftDataBook {
        @Attribute(.unique) public var id: UUID
        public var title: String
        public var author: String?
        public var managementNumber: String?
        public var isbn13: String?
        public var publisher: String?
        public var publishedDate: String?
        public var bookDescription: String?
        public var smallThumbnail: String?
        public var thumbnail: String?
        public var targetAge: String?
        public var pageCount: Int?
        public var categories: [String]
        public var kanaGroup: KanaGroup?
        public init(
            id: UUID,
            title: String,
            author: String? = nil,
            isbn13: String? = nil,
            publisher: String? = nil,
            publishedDate: String? = nil,
            bookDescription: String? = nil,
            smallThumbnail: String? = nil,
            thumbnail: String? = nil,
            targetAge: String? = nil,
            pageCount: Int? = nil,
            categories: [String] = [],
            managementNumber: String? = nil,
            kanaGroup: KanaGroup? = nil
        ) {
            self.id = id
            self.title = title
            self.author = author
            self.managementNumber = managementNumber
            self.isbn13 = isbn13
            self.publisher = publisher
            self.publishedDate = publishedDate
            self.bookDescription = bookDescription
            self.smallThumbnail = smallThumbnail
            self.thumbnail = thumbnail
            self.targetAge = targetAge
            self.pageCount = pageCount
            self.categories = categories
            self.kanaGroup = kanaGroup
        }
    }
    
    public enum KanaGroup: String, CaseIterable, Sendable, Codable {
        case a = "あ"
        case ka = "か"
        case sa = "さ"
        case ta = "た"
        case na = "な"
        case ha = "は"
        case ma = "ま"
        case ya = "や"
        case ra = "ら"
        case wa = "わ"
        case other = "他"
    }
    
    @Model
    final public class SwiftDataClassGroup {
        @Attribute(.unique) public var id: UUID
        public var name: String
        public var ageGroup: String
        public var year: Int
        public init(id: UUID, name: String, ageGroup: String, year: Int) {
            self.id = id
            self.name = name
            self.ageGroup = ageGroup
            self.year = year
        }
    }
    
    public struct User: Identifiable, Codable, Hashable {
        public var id: UUID
        public var name: String
        public var classGroupId: UUID
        public init(
            id: UUID = UUID(),
            name: String,
            classGroupId: UUID,
        ) {
            self.id = id
            self.name = name
            self.classGroupId = classGroupId
        }
    }
}
