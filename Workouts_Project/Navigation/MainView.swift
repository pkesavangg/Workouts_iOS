//
//  MainView.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 22/06/25.
//
import SwiftUI

struct MainView: View {
    var body: some View {
        TabView {
            MenuView()
                .tabItem {
                    Label("Menu", systemImage: "list.dash")
                }
            
            OrderView()
                .tabItem {
                    Label("Order", systemImage: "square.and.pencil")
                }
        }
    }
}

struct MenuView: View {
    var body: some View {
        List(0..<100) { index in
            Button {
            } label: {
                Text("Item \(index)")
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }
        }
        .font(.largeTitle)
        .padding()
        .background(Color.gray.opacity(0.2))
        .onAppear {
            print("MenuView appeared")
        }
    }
}


struct OrderView: View {
    var body: some View {
        Text("Menu")
            .font(.largeTitle)
            .padding()
            .background(Color.gray.opacity(0.2))
            .onAppear {
                print("Order View appeared")
            }
    }
}

#Preview(body: {
    MainView()
})
