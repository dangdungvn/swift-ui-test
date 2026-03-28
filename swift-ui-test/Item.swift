//
//  Item.swift
//  swift-ui-test
//
//  Created by Phan Văn Tùng on 28/3/26.
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
