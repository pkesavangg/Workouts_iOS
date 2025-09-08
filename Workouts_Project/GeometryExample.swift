//
//  GeometryExample.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 01/09/25.
//


import SwiftUI

struct GeometryExample: View {
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Text("Width: \(geometry.size.width)")
                Text("Height: \(geometry.size.height)")
                Text("Height: \(geometry.safeAreaInsets.bottom)")
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(Color.blue.opacity(0.2))
        }
    }
}

#Preview {
    GeometryExample()
}
