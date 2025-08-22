//
//  WeightEntriesViewModel.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 04/07/25.
//

import Foundation
import SwiftUI

@MainActor
final class WeightEntriesViewModel: ObservableObject {
    @Published var entries: [WeightEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isLoggedIn = false
    
    private var accessToken: String?
    private let loginEmail = "pkesavan@greatergoods.com"
    private let loginPassword = "1234567"
    
    // MARK: - Login
    func login() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let loginRequest = LoginRequest(email: loginEmail, password: loginPassword)
            let loginData = try JSONEncoder().encode(loginRequest)
            
            guard let url = URL(string: "https://api.weightgurus.com/v3/account/login") else {
                throw URLError(.badURL)
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = loginData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            
            let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
            self.accessToken = loginResponse.accessToken
            self.isLoggedIn = true
            
            print("✅ Login successful for: \(loginResponse.account.firstName) \(loginResponse.account.lastName)")
            
            // Automatically fetch entries after successful login
            await fetchEntries()
            
        } catch {
            self.errorMessage = "Login failed: \(error.localizedDescription)"
            print("❌ Login error: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Fetch Entries
    func fetchEntries() async {
        guard let token = accessToken else {
            errorMessage = "Not logged in. Access token missing."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            guard let url = URL(string: "https://api.weightgurus.com/v3/operation/r4") else {
                throw URLError(.badURL)
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            
            let entriesResponse = try JSONDecoder().decode(EntriesResponse.self, from: data)
            
            // Filter and sort entries - show only create operations, most recent first
            let createEntries = entriesResponse.operations
                .filter { $0.isCreateOperation }
                .sorted { e1, e2 in
                    let d1 = iso8601WithMillis.date(from: e1.entryTimestamp) ?? .distantPast
                    let d2 = iso8601WithMillis.date(from: e2.entryTimestamp) ?? .distantPast
                    return d1 > d2            // newest first
                }

            self.entries = createEntries
            
            #if DEBUG
            print("✅ Fetched \(createEntries.count) weight entries")
            print("First entry: \(createEntries.first?.entryTimestamp ?? "none")")
            #endif
            
            print("Fetched \(self.entries.count) valid entries")
        } catch {
            self.errorMessage = "Failed to fetch entries: \(error.localizedDescription)"
            print("❌ Fetch entries error: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Refresh Data
    func refreshData() async {
        if !isLoggedIn {
            await login()
        } else {
            await fetchEntries()
        }
    }
    
    // MARK: - Logout
    func logout() {
        accessToken = nil
        isLoggedIn = false
        entries.removeAll()
        errorMessage = nil
    }
}

// Put this at file scope or inside WeightEntriesViewModel
private let iso8601WithMillis: ISO8601DateFormatter = {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    f.timeZone = TimeZone(secondsFromGMT: 0)
    return f
}()
