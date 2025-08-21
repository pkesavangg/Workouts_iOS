//
//  ScrollSpacerView.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 10/07/25.
//

import SwiftUI

import SwiftUI

struct ScrollSpacerView: View {
    @State var text: String = "Hello, World!"

    var body: some View {
        VStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Hello, World!")

                    VStack(spacing: 24) {
                        ForEach(0..<6) { _ in
                            TextField("Type something", text: $text)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    .padding(.top)

                    Spacer(minLength: 0)

                    VStack(spacing: 4) {
                        Text("Footer content")
                            .font(.headline)
                        Text("This is a scrollable view with a spacer at the bottom.")
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 32)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.5))
                .frame(minHeight: UIScreen.main.bounds.height) // Makes sure the view fills the screen
            }
        }
        .background(Color.red.opacity(0.5).ignoresSafeArea())
    }
}


#Preview {
    HalfSheetExampleContentView()
}
import SwiftUI

struct HalfSheetExampleContentView: View {
    @State private var showSheet = false
    @State private var selectedDetent: PresentationDetent = .medium

    var body: some View {
        Button("Show half sheet") { showSheet = true }
            .sheet(isPresented: $showSheet) {
                HalfSheetExample()
                    .presentationDetents([.height(320)]) // Use fixed height
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(24)
                    .interactiveDismissDisabled(false)
            }


    }
}
struct HalfSheetExample: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Half Sheet on iPad")
                .font(.title2).bold()

            Text("Fixed height: 320")

            ScrollView {
                ForEach(0..<10) { i in
                    RoundedRectangle(cornerRadius: 12)
                        .frame(height: 40)
                        .overlay(Text("Row \(i)"))
                        .padding(.horizontal)
                }
            }
            .frame(maxHeight: 200) // ⬅️ This is key
        }
        .padding()
    }
}

