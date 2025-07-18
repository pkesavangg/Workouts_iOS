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
                }
            }
            .navigationTitle("Devices")
        }
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
    let container = try! ModelContainer(for: Device.self, BathScale.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))

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
