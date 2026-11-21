//
//  Item.swift
//  Sylantro
//
//  Created by Wayne Mock on 11/20/26.
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
