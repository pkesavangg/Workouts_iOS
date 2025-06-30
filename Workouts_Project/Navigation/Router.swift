//
//  Router.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 22/06/25.
//


//
//  Router.swift
//  meApp
//
//  Created by Kesavan Panchabakesan on 28/05/25.
//

import Foundation

// MARK: - Array Extension
/// This extension provides a method to truncate an array to a specific index.
extension Array {
    mutating func truncate(to index: Int) {
        guard index < self.count && index >= 0 else {
            return
        }
        self = Array(self[..<Swift.min(index + 1, self.count)])
    }
}

// Safe subscript for arrays
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}


import Foundation
import SwiftUI

// MARK: - Router
//  An observable navigation manager that conforms to `RoutableObject` for handling navigation stack logic.
//  - Holds a published stack of `Routes` to drive navigation updates in SwiftUI.
//  - Designed for use with `RoutingView` to enable programmatic navigation.
//

public final class Router<Routes: Routable>: RoutableObject, ObservableObject {
    public typealias Destination = Routes

    @Published public var stack: [Routes] = []

    public init() {}
}


