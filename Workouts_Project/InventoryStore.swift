//
//  InventoryStore.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 10/08/25.
//

import Foundation
import SwiftUI

actor InventoryStore {
    private var stock: [String: Int] = [:]
    
    func get(_ sku: String) -> Int { stock[sku, default: 0] }
    
    func add(_ sku: String, qty: Int) {
        stock[sku, default: 0] += qty
    }
}

@MainActor
class InventoryManager: ObservableObject {
    private let store: InventoryStore
    @Published var stock: Int = 0
        
    init(store: InventoryStore = InventoryStore()) {
        self.store = store
        getStock(for: "w3")
    }
    
    func getStock(for sku: String) {
        Task {
            self.stock = await store.get(sku)
        }
    }
    
    func addStock(for sku: String, quantity: Int) {
        Task {
            await store.add(sku, qty: quantity)
            getStock(for: sku)
        }
    }
}


struct InventoryManagerDemo: View {
    @StateObject private var inventoryManager = InventoryManager()
    var body: some View {
        VStack {
            Text("Current Stock: \(inventoryManager.stock)")
                .padding()
            Button("Add Stock") {
                Task {
                    await                 inventoryManager.addStock(for: "w3", quantity: 10)

                }
            }
        }
    }
}

#Preview{
    InventoryManagerDemo()
}
