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
}
