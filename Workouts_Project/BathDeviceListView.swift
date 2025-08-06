//
//  DeviceListView.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 18/07/25.
//


import SwiftUI
import SwiftData

struct BathDeviceListView: View {
    @Query var devices: [BathDevice]
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationView {
            List {
                ForEach(devices, id: \.id) { device in
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Device ID: \(device.id)")
                            .font(.headline)
                        Text("Account ID: \(device.accountId)")
                        if let sku = device.sku {
                            Text("SKU: \(sku)")
                        }
                        if let mac = device.mac {
                            Text("MAC: \(mac)")
                        }
                        if let proto = device.protocolType {
                            Text("Protocol: \(proto)")
                        }
                        if let scale = device.bathScale {
                            Divider()
                            Text("Scale Type: \(scale.scaleType ?? "N/A")")
                            Text("Body Comp: \(scale.bodyComp == true ? "Yes" : "No")")
                        }
                    }
                    .padding(.vertical, 8)
                    // Swipe action to delete only the associated BathScale
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if device.bathScale != nil {
                            Button(role: .destructive) {
                                deleteScale(for: device)
                            } label: {
                                Label("Delete Scale", systemImage: "trash")
                            }
                        }
                    }
                }
                .onDelete(perform: deleteDevices)
            }
            .navigationTitle("\(devices.count) Devices")
            .toolbar {
                Button(action: addRandomDevice) {
                    Label("Add Device", systemImage: "plus")
                }
            }
        }
    }

    private func addRandomDevice() {
        print("Adding a random device...")
        let randomId = UUID().uuidString
        let randomAccount = "user_\(Int.random(in: 1...999))"
        let randomSKU: String? = Bool.random() ? "SKU\(Int.random(in: 1000...9999))" : nil
        let randomMac: String? = Bool.random() ? (0..<6).map { _ in String(format: "%02X", Int.random(in: 0...255)) }.joined(separator: ":") : nil
        let randomProtocol: String? = ["r1", "r2", "r3", "r4"].randomElement()

        let randomScale: BathScale? = Bool.random() ? BathScale(scaleType: ["Bluetooth", "WiFi"].randomElement(), bodyComp: Bool.random()) : nil

        let newDevice = BathDevice(id: randomId,
                                   accountId: randomAccount,
                                   sku: randomSKU,
                                   mac: randomMac,
                                   protocolType: randomProtocol,
                                   bathScale: randomScale)

        withAnimation {
            modelContext.insert(newDevice)
        }

        try? modelContext.save()
    }

    private func deleteDevices(at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(devices[index])
            }
        }

        try? modelContext.save()
    }

    // MARK: - Delete only BathScale from a specific device
    private func deleteScale(for device: BathDevice) {
        guard let scale = device.bathScale else { return }

        withAnimation {
            // Break the relationship first, then remove the scale from the context
            device.bathScale = nil
            modelContext.delete(scale)
        }

        try? modelContext.save()
    }
}


import Foundation
import SwiftData

@Model
final class BathDevice {
    @Attribute(.unique) var id: String
    var accountId: String
    var sku: String?
    var mac: String?
    var protocolType: String?
    
    @Relationship(deleteRule: .cascade) var bathScale: BathScale?
    
    init(id: String, accountId: String, sku: String? = nil, mac: String? = nil, protocolType: String? = nil, bathScale: BathScale? = nil) {
        self.id = id
        self.accountId = accountId
        self.sku = sku
        self.mac = mac
        self.protocolType = protocolType
        self.bathScale = bathScale
    }
}

@Model
final class BathScale {
    var scaleType: String?
    var bodyComp: Bool?
    
    init(scaleType: String?, bodyComp: Bool?) {
        self.scaleType = scaleType
        self.bodyComp = bodyComp
    }
}

extension BathScale: @unchecked Sendable {}


#Preview {
    let container = try! ModelContainer(for: BathDevice.self, BathScale.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))

    // Create sample data
    let sampleScale = BathScale(scaleType: "Bluetooth", bodyComp: true)
    let sampleDevice = BathDevice(
        id: UUID().uuidString,
        accountId: "user_001",
        sku: "GG1234",
        mac: "00:1A:22:33:44:55",
        protocolType: "r4",
        bathScale: sampleScale
    )

    container.mainContext.insert(sampleDevice)

    return BathDeviceListView()
        .modelContainer(container)
}
