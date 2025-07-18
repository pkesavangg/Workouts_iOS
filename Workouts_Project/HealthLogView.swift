//
//  HealthLogView.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 01/07/25.
//


import SwiftUI

struct HealthLogView: View {
    @State private var responseMessage: String = "No response yet"

    var body: some View {
        VStack(spacing: 20) {
            Text("Health Log Integration")
                .font(.title)

            Button("Send Fake Health Log") {
                Task {
                    await sendHealthLog()
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)

            Text(responseMessage)
                .padding()
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    func sendHealthLog() async {
        guard let url = URL(string: "https://api.weightgurus.com/v3/integrations/health/log") else {
            responseMessage = "Invalid URL"
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // ⚠️ Replace "YOUR_AUTH_TOKEN" with your actual token
        request.setValue("Bearer XrVnZaYU7V3e/qMZc0T4mH9sbOpJxW+BRQ5AxkfxzMgB/Xm5pheqRxhyVnNi7Knpb3G2jwyLi+kx1IvYsCjdMg==", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any?] = [
            "type": "healthkit",
            "sentAt": ISO8601DateFormatter().string(from: Date()),
            "timestamp": ISO8601DateFormatter().string(from: Date().addingTimeInterval(-60)), // 1 min earlier
            "weight": nil,
            "bmi": nil,
            "bodyFat": nil,
            "muscleMass": nil,
            "water": nil,
            "data": [:]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])

            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    responseMessage = "✅ Success!"
                } else {
                    let responseText = String(data: data, encoding: .utf8) ?? "No response body"
                    responseMessage = "❌ HTTP \(httpResponse.statusCode): \(responseText)"
                }
            } else {
                responseMessage = "Unknown response"
            }
        } catch {
            responseMessage = "Error: \(error.localizedDescription)"
        }
    }
}

#Preview(body: {
    HealthLogView()
})
