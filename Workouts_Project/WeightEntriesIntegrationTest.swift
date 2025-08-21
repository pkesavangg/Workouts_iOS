//
//  WeightEntriesIntegrationTest.swift
//  Workouts_Project
//
//  Created by Assistant on 04/07/25.
//

import SwiftUI

// Simple integration test to verify all components work together
struct WeightEntriesIntegrationTest: View {
    var body: some View {
        VStack {
            Text("Testing WeightEntries Integration")
                .font(.title2)
                .padding()
            
            // Test TimePeriod enum
            Text("Time Periods: \(TimePeriod.allCases.map { $0.displayName }.joined(separator: ", "))")
                .padding()
            
            // Test TimePeriodSelector
            TimePeriodSelector(selectedPeriod: .constant(.month))
                .padding()
            
            // Test with sample data
            WeightChartView(entries: sampleEntries)
                .padding()
            
            Spacer()
        }
    }
    
    private var sampleEntries: [WeightEntry] {
        let now = Date()
        return (0..<10).map { i in
            WeightEntry(
                operationType: "create",
                entryTimestamp: ISO8601DateFormatter().string(from: now.addingTimeInterval(Double(i) * -24 * 60 * 60)),
                serverTimestamp: "",
                weight: 7000 + Int.random(in: -200...200), // ~70kg ± 2kg
                bodyFat: nil,
                muscleMass: nil,
                boneMass: nil,
                water: nil,
                source: "manual",
                bmi: 250,
                impedance: nil,
                pulse: nil,
                unit: "kg",
                visceralFatLevel: nil,
                subcutaneousFatPercent: nil,
                proteinPercent: nil,
                skeletalMusclePercent: nil,
                bmr: nil,
                metabolicAge: nil
            )
        }
    }
}

#Preview {
    WeightEntriesIntegrationTest()
}
