//
//  NativeTab.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 15/06/25.
//


import SwiftUI


#Preview(body: {
    CustomTabView()
})
import SwiftUI

enum TabItem: String, CaseIterable {
    case dash, entry, history, settings, appsync

    var label: String {
        switch self {
        case .dash: return "dash"
        case .entry: return "entry"
        case .history: return "history"
        case .settings: return "settings"
        case .appsync: return "appsync"
        }
    }

    var icon: String {
        switch self {
        case .dash: return "rectangle.connected.to.line.below"
        case .entry: return "plus"
        case .history: return "doc.text"
        case .settings: return "gearshape"
        case .appsync: return "viewfinder"
        }
    }

    var filledIcon: String {
        switch self {
        case .dash: return "rectangle.connected.to.line.below"
        case .entry: return "plus.circle.fill"
        case .history: return "doc.text.fill"
        case .settings: return "gearshape.fill"
        case .appsync: return "viewfinder.circle.fill"
        }
    }
}

struct CustomTabView: View {
    @State private var selectedTab: TabItem = .dash
    @State private var showSettingsBadge = true

    var body: some View {
        VStack {

            List(0..<100) { item in
                Text("Item \(item)")
            }
            //Color.red
            Spacer(minLength: 0)


            HStack {
                ForEach(TabItem.allCases, id: \.self) { tab in
                    Spacer()

                    Button {
                        selectedTab = tab
                        if tab == .settings {
                            showSettingsBadge = false
                        }
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            VStack(spacing: 4) {
                                Image(systemName: selectedTab == tab ? tab.filledIcon : tab.icon)
                                    .font(.system(size: 24))
                                    .foregroundColor(selectedTab == tab ? .black : .primary)

                                Text(tab.label)
                                    .font(.caption)
                            }

                            // Red dot on Settings
                            if tab == .settings && showSettingsBadge {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                    .offset(x: -6, y: 16)
                            }
                        }
                    }

                    Spacer()
                }
            }
            .padding(.top, 8)
//            .padding(.bottom, .SpacingMD)
            
            .background(Color(UIColor.systemGroupedBackground))
        }
        .edgesIgnoringSafeArea(.bottom)
    }
}




//enum NativeTab: Int {
//    case dash, entry, history, settings, appsync
//}
//
//struct NativeTabView: View {
//    @State private var selectedTab: NativeTab = .dash
//    @State private var showSettingsBadge: Bool = true
//
//    var body: some View {
//        TabView(selection: $selectedTab) {
//            Color.white
//                .tabItem {
//                    Image(systemName: selectedTab == .dash ? "square.and.arrow.up.fill" : "rectangle.connected.to.line.below")
//                    Text("dash")
//                }
//                .tag(NativeTab.dash)
//
//            Color.white
//                .tabItem {
//                    Image(systemName: selectedTab == .entry ? "plus.circle.fill" : "plus")
//                    Text("entry")
//                }
//                .tag(NativeTab.entry)
//
//            Color.white
//                .tabItem {
//                    Image(systemName: selectedTab == .history ? "doc.text.fill" : "doc.text")
//                    Text("history")
//                }
//                .tag(NativeTab.history)
//
//            Color.white
//                .tabItem {
//                    ZStack {
////                        if showSettingsBadge {
////                            Image("settingBadge")
////
////                        } else {
////                            Image(systemName: selectedTab == .settings ? "gearshape.fill" : "gearshape")
////                        }
//                        Image("settingBadge")
//                            .renderingMode(.template)
//                            .foregroundColor(showSettingsBadge ? .black : .gray)
//                    }
//                    Text("settings")
//                        .font(.headline)
//                }
//                .tag(NativeTab.settings)
//
//            Color.white
//                .tabItem {
//                    Image(systemName: selectedTab == .appsync ? "viewfinder.circle.fill" : "viewfinder")
//                    Text("appsync")
//                }
//                .tag(NativeTab.appsync)
//        }
//        .onChange(of: selectedTab) {
//            if selectedTab == .settings {
//                showSettingsBadge = false
//            }
//        }
//        .accentColor(.yellow) // Change the accent color of the tab bar
//    }
//}
