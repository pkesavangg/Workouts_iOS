//
//  SheetNavigationView.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 15/07/25.
//

import SwiftUI

import SwiftUI

struct SheetNavigationView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Sheet View")
                    .font(.title)

                NavigationLink("Go to Detail View") {
                    DetailView()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Customize Settings")
        }

        
    }
}

struct DetailView: View {
    var body: some View {
        Text("This is the detail view inside the sheet!")
            .font(.title2)
            .padding()
            .navigationTitle("Detail")
    }
}


#Preview {
    SheetNavigationView()
}

import SwiftUI

struct SheetNavigationMainView: View {
    @State private var showSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Main View")
                    .font(.largeTitle)

                // Optional button to manually show again later
                Button("Open Sheet") {
                    showSheet = true
                }
                .buttonStyle(.borderedProminent)
            }
        }

        .onAppear {
            showSheet = true
        }
        .sheet(isPresented: $showSheet) {
            SheetNavigationView()
        }
    }
}

#Preview {
    SheetNavigationMainView()
}


#Preview {
    SheetNavigationMainView()
}
