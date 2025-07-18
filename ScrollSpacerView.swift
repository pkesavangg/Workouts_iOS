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
    ScrollSpacerView()
}
