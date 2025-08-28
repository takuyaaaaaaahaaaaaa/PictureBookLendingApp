//
//  SchemaV1_1.swift
//  PictureBookLendingAdmin
//
//  Created by takuya_tominaga on 8/28/25.
//

import Foundation
import SwiftData

struct PictureBookLendingSchemaV1_1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 1, 0) }
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
        public var userTypeRawValue: String = "child"
        public var relatedChildId: UUID?
        
        public init(
            id: UUID,
            name: String,
            classGroupId: UUID,
            userType: UserType
        ) {
            self.id = id
            self.name = name
            self.classGroupId = classGroupId
            
            switch userType {
            case .child:
                self.userTypeRawValue = "child"
                self.relatedChildId = nil
            case .guardian(let relatedChildId):
                self.userTypeRawValue = "guardian"
                self.relatedChildId = relatedChildId
            }
        }
    }
    
    public struct User: Identifiable, Codable, Hashable {
        public var id: UUID
        public var name: String
        public var classGroupId: UUID
        public var userType: UserType
        public init(
            id: UUID = UUID(),
            name: String,
            classGroupId: UUID,
            userType: UserType = .child
        ) {
            self.id = id
            self.name = name
            self.classGroupId = classGroupId
            self.userType = userType
        }
    }
    
    public enum UserType: Codable, Hashable {
        case child
        case guardian(relatedChildId: UUID)
    }
}
