//
//  AccessibleView.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 22/06/25.
//


import SwiftUI

struct AccessibleView: View {
    @State private var volume: Double = 50
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Music Player")
                .font(.title)
                .accessibilityAddTraits(.isHeader) // Makes it a header for VoiceOver

            Slider(value: $volume, in: 0...100)
                .accessibilityLabel("Volume")
                .accessibilityValue("\(Int(volume)) percent")

            Button(action: {
                print("Playing music")
            }) {
                Image(systemName: "play.circle.fill")
                    .resizable()
                    .frame(width: 60, height: 60)
            }
            .accessibilityLabel("Play")
            .accessibilityHint("Plays the current song")
        }
        .padding()
    }
}
