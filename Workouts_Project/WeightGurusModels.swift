//
//  WeightGurusModels.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 04/07/25.
//

import Foundation

// MARK: - Login Models
struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct LoginResponse: Codable {
    let account: AccountInfo
    let accessToken: String
    let refreshToken: String
    let expiresAt: String
}

struct AccountInfo: Codable {
    let id: String
    let email: String
    let firstName: String
    let lastName: String
    let gender: String
    let zipcode: String
    let weightUnit: String
    let isWeightlessOn: Bool
    let preferredInputMethod: String?
    let height: Int
    let activityLevel: String
    let dob: String
    let weightlessBodyFat: Double?
    let weightlessMuscle: Double?
    let weightlessTimestamp: String?
    let weightlessWeight: Double?
    let isStreakOn: Bool
    let dashboardType: String
    let dashboardMetrics: [String]
    let goalType: String
    let goalWeight: Int
    let initialWeight: Int
    let shouldSendEntryNotifications: Bool
    let shouldSendWeightInEntryNotifications: Bool
}

// MARK: - Entries Models
struct EntriesResponse: Codable {
    let operations: [WeightEntry]
}

struct WeightEntry: Codable, Identifiable {
    let id = UUID()
    let operationType: String
    let entryTimestamp: String
    let serverTimestamp: String
    let weight: Int
    let bodyFat: Double?
    let muscleMass: Double?
    let boneMass: Double?
    let water: Double?
    let source: String
    let bmi: Double?
    let impedance: Double?
    let pulse: Double?
    let unit: String?
    let visceralFatLevel: Double?
    let subcutaneousFatPercent: Double?
    let proteinPercent: Double?
    let skeletalMusclePercent: Double?
    let bmr: Double?
    let metabolicAge: Double?
    
    private enum CodingKeys: String, CodingKey {
        case operationType, entryTimestamp, serverTimestamp, weight, bodyFat, muscleMass, boneMass, water, source, bmi, impedance, pulse, unit, visceralFatLevel, subcutaneousFatPercent, proteinPercent, skeletalMusclePercent, bmr, metabolicAge
    }
}

// MARK: - Helper Extensions
extension WeightEntry {
    var formattedWeight: String {
        let weightValue = Double(weight) / 100.0
        let unitString = unit ?? "kg"
        return String(format: "%.1f %@", weightValue, unitString)
    }
    
    var formattedDate: String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: entryTimestamp) else { return entryTimestamp }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .short
        return displayFormatter.string(from: date)
    }
    
    var isCreateOperation: Bool {
        return operationType.lowercased() == "create"
    }
    
    var isDeleteOperation: Bool {
        return operationType.lowercased() == "delete"
    }
}
