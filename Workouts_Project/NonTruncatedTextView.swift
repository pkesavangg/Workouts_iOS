//
//  NonTruncatedTextView.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 28/07/25.
//

import SwiftUI

struct NonTruncatedTextView: View {
    var body: some View {
        VStack {
            Text("Here’s a headline that’s 40 characters.")
                .fontWeight(.bold)
    //            .lineLimit(2) // Prevents truncation
                .frame(width: 100)
            
            Text("Here’s a headline that’s 40 characters.".uppercased())
                .font(.body)
                .foregroundColor(.blue) // Or use your theme's primary color
                .lineLimit(2)           // Limits to 2 lines
                .truncationMode(.tail)  // Adds "..." at the end
//                .multilineTextAlignment(.leading) 
        }
        .frame(width: 100)
// Optional: align text
            
    }
}

#Preview {
    NonTruncatedTextView()
}
