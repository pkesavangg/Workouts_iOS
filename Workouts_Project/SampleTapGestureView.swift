//
//  SampleTapGestureView.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 04/06/25.
//

import SwiftUI

struct SampleTapGestureView: View {
    var body: some View {
        ZStack {
            Color.blue
                .edgesIgnoringSafeArea(.all)
               
            Text("Hello, World!")
                .font(.largeTitle)
                .foregroundColor(.white)
                .padding()
        }
        .onTapGesture {
            print("Tapped!")
        }
    }
}

#Preview {
    SampleTapGestureView()
}
