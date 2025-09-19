//
//  Item.swift
//  aijailbreak
//
//  Created by user20 on 2025/9/19.
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
