//
//  Item.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 25/05/25.
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
