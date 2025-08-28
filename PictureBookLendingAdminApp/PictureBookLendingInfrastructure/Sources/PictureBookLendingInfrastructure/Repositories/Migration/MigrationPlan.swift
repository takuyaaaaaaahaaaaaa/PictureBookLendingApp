//
//  MigrationPlan.swift
//  PictureBookLendingAdmin
//
//  Created by takuya_tominaga on 8/28/25.
//

import SwiftData

extension MigrationStage: @unchecked @retroactive Sendable {}

enum PictureBookLendingMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [PictureBookLendingSchemaV1.self, PictureBookLendingSchemaV1_1.self]
    }
    
    static var stages: [MigrationStage] {
        [migrateV1ToV1_1]
    }
    
    static let migrateV1ToV1_1: MigrationStage = MigrationStage.custom(
        fromVersion: PictureBookLendingSchemaV1.self,
        toVersion: PictureBookLendingSchemaV1_1.self,
        willMigrate: { context in
            // 旧スキーマの Loan を全削除
            try context.delete(model: PictureBookLendingSchemaV1.SwiftDataLoan.self)
            try context.save()
        },
        didMigrate: nil
    )
}
