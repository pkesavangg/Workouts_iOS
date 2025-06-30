//
//  CoreData_Testing_View.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 03/06/25.
//

import SwiftUI

struct CoreData_Testing_View: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    CoreData_Testing_View2()
}


import SwiftData

@Model
final class SampleAccount {
    @Attribute(.unique) var id: UUID
    var name: String
    var email: String

    init(id: UUID = UUID(), name: String, email: String) {
        self.id = id
        self.name = name
        self.email = email
    }
}

import SwiftData

@MainActor
final class AccountRepository3: ObservableObject {

    @Published var accounts: [SampleAccount] = []
    // MARK: - Properties
    private let context: ModelContext

    let contexte : ModelContext = DataStore.shared.context

    init() {
        self.context = contexte
    }
    
//    private let container: ModelContainer
//    private let context: ModelContext
//
//    init() {
//        let schema = Schema([SampleAccount.self])
//        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
//        self.container = try! ModelContainer(for: schema, configurations: [config])
//        self.context = ModelContext(container)
//    }

    func fetchAccounts() {
        do {
            let descriptor = FetchDescriptor<SampleAccount>(sortBy: [.init(\.name)])
            accounts = try context.fetch(descriptor)
        } catch {
            print("Failed to fetch accounts: \(error)")
        }
    }

    func addAccount(name: String, email: String) {
        let account = SampleAccount(name: name, email: email)
        context.insert(account)

        do {
            try context.save()
            fetchAccounts()
        } catch {
            print("Failed to save account: \(error)")
        }
    }
}

import SwiftUI
import SwiftData

struct CoreData_Testing_View2: View {
    @StateObject private var repo: AccountRepository3 = AccountRepository3()

    @State private var name = ""
    @State private var email = ""


    var body: some View {
        VStack(spacing: 20) {
            TextField("Name", text: $name)
                .textFieldStyle(.roundedBorder)
            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
            Button("Add Account") {
                repo.addAccount(name: name, email: email)
                name = ""
                email = ""
            }
            .buttonStyle(.borderedProminent)

            List(repo.accounts, id: \.id) { account in
                VStack(alignment: .leading) {
                    Text(account.name)
                    Text(account.email).font(.subheadline).foregroundColor(.gray)
                }
            }
        }
        .padding()
        .onAppear {
            Task {
                repo.fetchAccounts()
            }
        }
    }
}

import SwiftData

@Model
final class Device {
    @Attribute(.unique) var id: UUID
    var name: String

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

import SwiftData
import Foundation

@MainActor
final class DeviceRepository: ObservableObject {

    @Published var devices: [Device] = []

    private let container: ModelContainer
    private let context: ModelContext

    init() {
        let schema = Schema([Device.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        self.container = try! ModelContainer(for: schema, configurations: [config])
        self.context = ModelContext(container)
    }

    func fetchDevices() {
        do {
            let descriptor = FetchDescriptor<Device>(sortBy: [.init(\.name)])
            devices = try context.fetch(descriptor)
        } catch {
            print("Failed to fetch devices: \(error)")
        }
    }

    func addDevice(name: String) {
        let device = Device(name: name)
        context.insert(device)

        do {
            try context.save()
            fetchDevices()
        } catch {
            print("Failed to save device: \(error)")
        }
    }

    func insertFakeDevices(count: Int = 10000) async {
        let start = Date()

        for i in 1...count {
            let device = Device(name: "Fake Device \(i)")
            context.insert(device)
        }

        do {
            try context.save()
            let duration = Date().timeIntervalSince(start)
            print("Inserted \(count) devices in \(duration) seconds")
            fetchDevices()
        } catch {
            print("Failed to insert fake devices: \(error)")
        }
    }

    func deleteAllDevices() async {
        let start = Date()
        do {
            let allDevices = try context.fetch(FetchDescriptor<Device>())
            for device in allDevices {
                context.delete(device)
            }
            try context.save()
            let duration = Date().timeIntervalSince(start)
            print("Deleted all devices in \(duration) seconds")
            fetchDevices()
        } catch {
            print("Failed to delete all devices: \(error)")
        }
    }
    
    
}


import SwiftUI
import SwiftData

struct DeviceListView: View {
    @StateObject private var repo = DeviceRepository()
    @State private var name = ""

    var body: some View {
        VStack(spacing: 20) {
            TextField("Device Name", text: $name)
                .textFieldStyle(.roundedBorder)

            Button("Add Device") {
                repo.addDevice(name: name)
                name = ""
            }
            .buttonStyle(.borderedProminent)

            HStack {
                Button("Insert 1000 Fake Devices") {
                    Task {
                        await repo.insertFakeDevices()
                    }
                }

                Button("Delete All Devices") {
                    Task {
                        await repo.deleteAllDevices()
                    }
                }
            }

            List(repo.devices, id: \.id) { device in
                Text(device.name)
            }
        }
        .padding()
        .onAppear {
            Task {
                repo.fetchDevices()
            }
        }
    }
}


