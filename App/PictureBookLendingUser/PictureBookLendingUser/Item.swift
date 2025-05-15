//
//  Item.swift
//  PictureBookLendingUser
//
//  Created by takuya_tominaga on 5/16/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
