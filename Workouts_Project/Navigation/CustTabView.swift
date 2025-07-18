//
//  TabView.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 22/06/25.
//

import SwiftUI
import SwiftUI

// This file defines the authentication routes for the app.
enum DashboardRoute: Routable {
    case home
    case history
    case settings
    case homeDetail(item: Int)
    
    var body: some View {
        switch self {
        case .home:
            HomeScreen()
        case .history:
            HistoryScreen()
        case .settings:
            SettingScreen()
        case .homeDetail(let item):
            Text("Detail for item \(item)")
            
        }
    }
}



enum AuthRoute: Routable {
    case login
    case signup
    
    var body: some View {
        switch self {
        case .login:
            Text("Login Screen")
        case .signup:
            Text("Signup Screen")
        }
    }
}

struct LandingScreen: View {
    @StateObject private var router = Router<AuthRoute>()
    var body: some View {
        RoutingView(stack: $router.stack) {
            VStack(spacing: 20) {
                Button {
                    router.navigate(to: .login)
                } label: {
                    Text("Login")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Button {
                    router.navigate(to: .signup)
                } label: {
                    Text("Signup")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
            }
        }
        .environmentObject(router)
    }
}

struct HomeScreen: View {
    @EnvironmentObject var router: Router<DashboardRoute>
    var body: some View {
        List(0..<100) { index in
            Button {
                router.navigate(to: .homeDetail(item: index))
            } label: {
                Text("Item \(index)")
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            print("Home Screen appeared")
        }
    }
}

struct HistoryScreen: View {
    @EnvironmentObject var router: Router<DashboardRoute>
    var body: some View {
        List(0..<100) { index in
            Button {
                router.navigate(to: .homeDetail(item: index))
            } label: {
                Text("History Item \(index)")
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            print("Home Screen appeared")
        }
    }
}

struct SettingScreen: View {
    var body: some View {
        Text("Settings Screen").font(.largeTitle)
            .navigationBarHidden(true)
            .onAppear {
                print("Settings Screen appeared")
            }
    }
}


struct TabBarItem: Hashable {
    let title: String
    let icon: String
    let tag: Int
}

extension TabBarItem {
    var route: DashboardRoute {
        switch tag {
        case 0: return .home
        case 1: return .history
        case 2: return .settings
        default: return .home
        }
    }
}


struct TabBarView: View {
    @Binding var selectedTab: TabBarItem
    let tabs: [TabBarItem]
    
    var body: some View {
        HStack {
            ForEach(tabs, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20, weight: .medium))
                        Text(tab.title)
                            .font(.caption)
                    }
                    .foregroundColor(selectedTab == tab ? .blue : .gray)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 4)
        .padding()
    }
}




struct CustTabView: View {
    let tabItems = [
        TabBarItem(title: "Home", icon: "house.fill", tag: 0),
        TabBarItem(title: "History", icon: "clock.fill", tag: 1),
        TabBarItem(title: "Settings", icon: "gearshape.fill", tag: 2)
    ]

    @State private var selectedTab: TabBarItem
    @StateObject private var homeRouter = Router<DashboardRoute>()
    @StateObject private var historyRouter = Router<DashboardRoute>()
    @StateObject private var settingsRouter = Router<DashboardRoute>()

    // Persisted root views
    @State private var homeScreen = HomeScreen()
    @State private var historyScreen = HistoryScreen()
    @State private var settingsScreen = SettingScreen()

    init() {
        _selectedTab = State(initialValue: tabItems[0])
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Home Tab
            StatefulView(isVisible: selectedTab.tag == 0) {
                RoutingView(stack: $homeRouter.stack) {
                    homeScreen.environmentObject(homeRouter)
                }
                .environmentObject(homeRouter)
            }

            // History Tab
            StatefulView(isVisible: selectedTab.tag == 1) {
                RoutingView(stack: $historyRouter.stack) {
                    historyScreen.environmentObject(historyRouter)
                }
                .environmentObject(historyRouter)
            }

            // Settings Tab (doesn't navigate deeper, but still wrapped for consistency)
            StatefulView(isVisible: selectedTab.tag == 2) {
                RoutingView(stack: $settingsRouter.stack) {
                    settingsScreen.environmentObject(settingsRouter)
                }
                .environmentObject(settingsRouter)
            }

            TabBarView(selectedTab: $selectedTab, tabs: tabItems)
        }
    }
}


#Preview {
    CustTabView()
}
struct StatefulView<Content: View>: View {
    let content: Content
    var isVisible: Bool

    init(isVisible: Bool, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.isVisible = isVisible
    }

    var body: some View {
        content
            .opacity(isVisible ? 1 : 0)
            .allowsHitTesting(isVisible)
    }
}
