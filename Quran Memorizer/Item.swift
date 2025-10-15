//
//  Item.swift
//  Quran Memorizer
//
//  Created by Donald Cjapi on 15/10/25.
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
