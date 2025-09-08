//
//  LocalHostTesting.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 24/08/25.
//

import SwiftUI

#Preview {
    LocalHostTesting()
}


import SwiftUI
import Foundation

struct LocalHostTesting: View {
    @State private var responseData: String = "Loading..."

    var body: some View {
        VStack {
            Text(responseData)
                .padding()
            Button("Fetch Local Data") {
                fetchLocalData()
            }
        }
    }

    func fetchLocalData() {
        // Replace with your specific localhost URL and port
        guard let url = URL(string: "http://localhost:3000/api/users/check-display-name/Mas") else {
            responseData = "Invalid URL"
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                responseData = "Error: \(error.localizedDescription)"
                return
            }

            guard let data = data else {
                responseData = "No data received"
                return
            }

            if let dataString = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    responseData = dataString
                }
            } else {
                responseData = "Could not decode data"
            }
        }
        task.resume()
    }
}
