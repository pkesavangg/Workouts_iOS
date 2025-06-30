////
////  HKDemoVM.swift
////  Workouts_Project
////
////  Created by Kesavan Panchabakesan on 27/06/25.
////
//
//
//import SwiftUI
//import ggHealthKitPackage  // the package under test
//
//@MainActor
//final class HKDemoVM: ObservableObject {
//    @Published var status = "Starting…"
//
//    func run() async {
//        // 1. Configure the handler for Weight Gurus
//        let hk = AppleHealthHandler.shared
//        hk.setAppType(appType: .WEIGHT_GURUS)
//
//        // 2. Ask the user for Health permissions
//        status = "Requesting authorization…"
//        guard await hk.requestAuthorization() else {
//            status = "Authorization failed / was denied"
//            return
//        }
//
//        // 3. Build some dummy samples
//        let now = Date()
//        let samples: [HealthKitData] = [
//            .init(type: .weight,      value: 180,  timestamp: now), // lb
//            .init(type: .bodyFat,     value: 22.5, timestamp: now), // %
//            .init(type: .leanBodyMass,value: 140,  timestamp: now), // lb
//            .init(type: .bmi,         value: 25.0, timestamp: now),
//            .init(type: .heartRate,   value: 68,   timestamp: now)  // bpm
//        ]
//
//        // 4. Save them to HealthKit
//        do {
//            try await hk.saveData(samples)
//            status = "✅ Dummy data saved"
//        } catch {
//            status = "❌ Save failed: \(error)"
//        }
//    }
//}
//
//struct HKDemoView: View {
//    @StateObject private var vm = HKDemoVM()
//
//    var body: some View {
//        VStack(spacing: 12) {
//            Text(vm.status).padding()
//            Button("Run demo") {
//                Task { await vm.run() }
//            }
//        }
//        .padding()
//    }
//}
