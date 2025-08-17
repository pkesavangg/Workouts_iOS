//
//  Workouts_ProjectApp.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 25/05/25.
//

import SwiftUI
import SwiftData

@main
struct Workouts_ProjectApp: App {
    var body: some Scene {
        WindowGroup {
            VStack {
                UserView()
            }
        }
        .modelContainer(for: [Account.self, GoalSetting.self, BathDevice.self, BathScale.self, SampleAccount.self, UserData.self])
    }
}

struct RootView: View {
    var body: some View {
        AlertTestMainView()
    }
}

import SwiftData

final class DataStore {
    static let shared = DataStore()

    let container: ModelContainer
    let context: ModelContext

    private init() {
        let schema = Schema([SampleAccount.self, Device.self, Account.self, GoalSetting.self, UserData.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        self.container = try! ModelContainer(for: schema, configurations: [config])
        self.context = ModelContext(container)
    }
}
