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
            WeightEntriesListView()
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


import SwiftUI

struct ContentViewTab: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
    }
}

struct HomeView: View {
    var body: some View {
        NavigationView {
            Text("Welcome to Home!")
                .font(.title)
                .navigationTitle("Home")
                .onAppear {
                    print(">>> Home.onAppear()")
                }
        }
    }
}

struct SearchView: View {
    var body: some View {
        NavigationView {
            Text("Search something here...")
                .font(.title2)
                .navigationTitle("Search")
                .onAppear {
                    print(">>> SearchView.onAppear()")
                }
        }
    }
}

struct ProfileView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                    .padding()

                Text("Your Profile")
                    .font(.title)
                    .onAppear {
                        print(">>> ProfileView.onAppear()")
                    }
                    .task {
                        print(">>> ProfileView.task()")
                    }

            }
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    ContentView()
}
