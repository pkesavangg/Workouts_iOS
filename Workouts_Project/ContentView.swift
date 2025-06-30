//
//  ContentView.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 25/05/25.
//

import SwiftUI
import SwiftData
import Foundation

// MARK: - SwiftData Model
@Model
class OperationEntry {
    @Attribute(.unique) var entryTimestamp: String
    var operationType: String
    var serverTimestamp: String
    var weight: Int
    var bodyFat: Double?
    var muscleMass: Double?
    var boneMass: Double?
    var water: Double?
    var source: String
    var bmi: Double?
    var impedance: Double?
    var pulse: Double?
    var unit: String?
    var visceralFatLevel: Double?
    var subcutaneousFatPercent: Double?
    var proteinPercent: Double?
    var skeletalMusclePercent: Double?
    var bmr: Double?
    var metabolicAge: Double?

    init(
        operationType: String,
        entryTimestamp: String,
        serverTimestamp: String,
        weight: Int,
        bodyFat: Double?,
        muscleMass: Double?,
        boneMass: Double?,
        water: Double?,
        source: String,
        bmi: Double?,
        impedance: Double?,
        pulse: Double?,
        unit: String?,
        visceralFatLevel: Double?,
        subcutaneousFatPercent: Double?,
        proteinPercent: Double?,
        skeletalMusclePercent: Double?,
        bmr: Double?,
        metabolicAge: Double?
    ) {
        self.operationType = operationType
        self.entryTimestamp = entryTimestamp
        self.serverTimestamp = serverTimestamp
        self.weight = weight
        self.bodyFat = bodyFat
        self.muscleMass = muscleMass
        self.boneMass = boneMass
        self.water = water
        self.source = source
        self.bmi = bmi
        self.impedance = impedance
        self.pulse = pulse
        self.unit = unit
        self.visceralFatLevel = visceralFatLevel
        self.subcutaneousFatPercent = subcutaneousFatPercent
        self.proteinPercent = proteinPercent
        self.skeletalMusclePercent = skeletalMusclePercent
        self.bmr = bmr
        self.metabolicAge = metabolicAge
    }
}

struct OperationResponse: Codable {
    let operations: [Operation]
}

struct Operation: Codable, Identifiable {
    var id: UUID { UUID() }  // Used locally for SwiftUI
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
}

// MARK: - ContentView
struct ReactiveFormTestingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var savedEntries: [OperationEntry]
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            List {
                Section("Saved Operations") {
                    ForEach(savedEntries, id: \.entryTimestamp) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(entry.operationType.capitalized) - \(entry.weight/10) lbs")
                                .font(.headline)
                            Text("Entry: \(entry.entryTimestamp)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Weight Entries")
            .onAppear(perform: loadData)
            .alert("Error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { _ in errorMessage = nil }
            ), actions: {
                Button("OK", role: .cancel) {}
            }, message: {
                Text(errorMessage ?? "")
            })
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        loadData()
                    }
                }
            }
        }
    }

    // Fetch from API
    func loadData() {
        fetchOperations { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let ops):
                    saveToSwiftData(ops)
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    // Decode from API
    func fetchOperations(completion: @escaping (Result<[Operation], Error>) -> Void) {
        guard let url = URL(string: "https://api.weightgurus.com/v3/operation/r4") else {
            completion(.failure(URLError(.badURL)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer tWZs65wyEiOyeOMJtLsnVVDQOw+ZXPqcbPg/e16IhRrZka6iCTXHYGXOW7iIh8RG9c+Y1jlh2SND3A9ivXp3Lg==", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(OperationResponse.self, from: data)
                completion(.success(decoded.operations))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    // Save to SwiftData, handle create/delete operations
    func saveToSwiftData(_ ops: [Operation]) {
        // First, collect all entryTimestamps that have delete operations
        let deletedTimestamps = Set(ops.compactMap { op in
            op.operationType.lowercased() == "delete" ? op.entryTimestamp : nil
        })
        
        // Remove any existing entries that have been deleted
        for deletedTimestamp in deletedTimestamps {
            if let existingEntry = savedEntries.first(where: { $0.entryTimestamp == deletedTimestamp }) {
                modelContext.delete(existingEntry)
                print("Removed deleted entry with timestamp: \(deletedTimestamp)")
            }
        }
        
        // Process create operations, but skip if they have corresponding delete operations
        for op in ops {
            // Only process "create" operations
            guard op.operationType.lowercased() == "create" else {
                continue
            }
            
            // Skip if this entry has been deleted
            if deletedTimestamps.contains(op.entryTimestamp) {
                print("Skipping create operation for timestamp \(op.entryTimestamp) because it has been deleted")
                continue
            }
            
            // Skip if already exists in local storage
            if savedEntries.contains(where: { $0.entryTimestamp == op.entryTimestamp }) {
                continue
            }

            let entry = OperationEntry(
                operationType: op.operationType,
                entryTimestamp: op.entryTimestamp,
                serverTimestamp: op.serverTimestamp,
                weight: op.weight,
                bodyFat: op.bodyFat,
                muscleMass: op.muscleMass,
                boneMass: op.boneMass,
                water: op.water,
                source: op.source,
                bmi: op.bmi,
                impedance: op.impedance,
                pulse: op.pulse,
                unit: op.unit,
                visceralFatLevel: op.visceralFatLevel,
                subcutaneousFatPercent: op.subcutaneousFatPercent,
                proteinPercent: op.proteinPercent,
                skeletalMusclePercent: op.skeletalMusclePercent,
                bmr: op.bmr,
                metabolicAge: op.metabolicAge
            )

            modelContext.insert(entry)
            print("Added new entry with timestamp: \(op.entryTimestamp)")
        }

        do {
            try modelContext.save()
            print("Successfully saved changes to SwiftData")
        } catch {
            print("Failed to save to SwiftData: \(error)")
        }
    }
}

// MARK: - Preview
//#Preview {
//    ContentView()
//        .modelContainer(for: OperationEntry.self, inMemory: true)
//}
