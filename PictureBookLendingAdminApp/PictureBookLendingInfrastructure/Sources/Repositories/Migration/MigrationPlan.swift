//
//  MigrationPlan.swift
//  PictureBookLendingAdmin
//
//  Created by takuya_tominaga on 8/28/25.
//

import Foundation
import SwiftData

enum PictureBookLendingMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [
            PictureBookLendingSchemaV1.self, PictureBookLendingSchemaV1_1.self,
            PictureBookLendingSchemaV1_2.self,
            PictureBookLendingSchemaV1_3.self,
        ]
    }

    static var stages: [MigrationStage] {
        [migrateV1ToV1Point1, migrateV1Point1ToV1Point2, migrateV1Point2ToV1Point3]
    }

    static let migrateV1ToV1Point1: MigrationStage = MigrationStage.custom(
        fromVersion: PictureBookLendingSchemaV1.self,
        toVersion: PictureBookLendingSchemaV1_1.self,
        willMigrate: { context in
            // 旧スキーマの Loan を全削除
            try context.delete(model: PictureBookLendingSchemaV1.SwiftDataLoan.self)
            try context.save()
        },
        didMigrate: nil
    )

    static let migrateV1Point1ToV1Point2: MigrationStage = MigrationStage.custom(
        fromVersion: PictureBookLendingSchemaV1_1.self,
        toVersion: PictureBookLendingSchemaV1_2.self,
        willMigrate: nil,
        didMigrate: { context in
            // V1_2のBookデータを読み込み、thumbnailのfile://パスをlocalImageFileNameに移行
            let books = try context.fetch(
                FetchDescriptor<PictureBookLendingSchemaV1_2.SwiftDataBook>())

            for book in books {
                // thumbnailに絶対パス（file://）が保存されている場合、ファイル名を抽出してlocalImageFileNameに移行
                if let thumbnail = book.thumbnail, thumbnail.hasPrefix("file://") {
                    // file://から始まるパスからファイル名のみを抽出
                    if let url = URL(string: thumbnail) {
                        let fileName = url.lastPathComponent
                        // localImageFileNameに設定
                        book.localImageFileName = fileName
                        // thumbnailをクリア（外部URL専用にする）
                        book.thumbnail = nil
                    }
                }
            }

            try context.save()
        }
    )

    static let migrateV1Point2ToV1Point3: MigrationStage = MigrationStage.lightweight(
        fromVersion: PictureBookLendingSchemaV1_2.self,
        toVersion: PictureBookLendingSchemaV1_3.self
    )
}
