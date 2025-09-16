//
//  ScrollableGraphView.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 14/09/25.
//

import SwiftUI

//struct ScrollableGraphView: View {
//    var body: some View {
//        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
//    }
//}

#Preview {
    ScrollableGraphView()
}

import SwiftUI
import Charts

// MARK: - Sample Model
struct DataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

// MARK: - ViewModel with Sample Data
@MainActor
final class ChartVM: ObservableObject {
    @Published var points: [DataPoint] = []
    @Published var xScrollPosition: Date = Date()

    init() {
        generateSample()
    }

    func generateSample() {
        var arr: [DataPoint] = []
        let start = Calendar.current.startOfDay(for: Date().addingTimeInterval(-120*24*60*60)) // ~120 days ago
        var running = 100.0

        for day in 0..<180 { // 6 months of daily data
            let dt = Calendar.current.date(byAdding: .day, value: day, to: start)!
            // small random walk
            running += Double.random(in: -2.5...2.5)
            arr.append(.init(date: dt, value: max(0, running)))
        }
        points = arr
        xScrollPosition = points.last!.date
    }
}

// MARK: - Scrollable Line Chart
import SwiftUI
import Charts

struct ScrollableGraphView: View {
    @StateObject private var entriesVM = WeightEntriesViewModel()
    @State private var initialWindowDays: Int = 30
    @State private var xScrollPosition: Date = Date()
    @State private var points: [DataPoint] = []
    @State private var selectedDate: Date?
    @State var toggleView: Bool = false

    private var visibleLength: TimeInterval {
        TimeInterval(initialWindowDays * 24 * 60 * 60)
    }

    private var scrollReadOnlyBinding: Binding<Date> {
        Binding(get: { xScrollPosition }, set: { _ in })
    }

    private func rebuildPoints() {
        let pts = entriesVM.entries
            .compactMap { entry -> DataPoint? in
                guard let date = entry.entryDate else { return nil }
                let unit = entry.unit?.lowercased() ?? "kg"
                let raw = Double(entry.weight) / 10.0
                let valueKg = (unit == "lb" || unit == "lbs") ? (raw * 0.45359237) : raw
                return DataPoint(date: date, value: valueKg)
            }
            .sorted { $0.date < $1.date }
        points = pts
    }

    var body: some View {
        VStack(spacing: 12) {
            Button {
                toggleView.toggle()
            } label: {
                Text("Increment Count:\(xScrollPosition)")
            }


            
            HStack(spacing: 8) {
                Text("Visible window:")
                Button("14d") { initialWindowDays = 14 }
                Button("30d") { initialWindowDays = 30 }
                Button("90d") { initialWindowDays = 90 }
                Spacer()
                Button("Refresh") {
                    Task { await entriesVM.refreshData() }
                }
                Button("Reset Scroll") {
                    if let last = points.last?.date {
                        withAnimation { xScrollPosition = last }
                    }
                }
            }
            .font(.callout)
            .buttonStyle(.bordered)

            if entriesVM.isLoading {
                ProgressView()
                    .frame(height: 280)
            } else if points.isEmpty {
                Text("No data")
                    .foregroundStyle(.secondary)
                    .frame(height: 280)
            } else {
                if toggleView {
                    Chart {
                        chartSeries
                    }
                    .chartScrollableAxes(.horizontal)
                    .chartForegroundStyleScale([
                        "weight": .red,
                        "Other": .green
                    ])
                    .chartScrollPosition(x: $xScrollPosition)
                    .chartXSelection(value: $selectedDate)
                    .chartXVisibleDomain(length: visibleLength)
                    .frame(height: 280)
                } else {
                    Chart {
                        chartSeries
                    }
                    .chartScrollableAxes(.horizontal)
                    .chartScrollPosition(x: $xScrollPosition)
                    .chartXSelection(value: $selectedDate)
                    .chartXVisibleDomain(length: visibleLength)
                    .frame(height: 280)
                }
                

            }
        }
        .task {
            await entriesVM.refreshData()
        }
        .onChange(of: entriesVM.entries) { _ in
            rebuildPoints()
            if let last = points.last?.date {
                xScrollPosition = last
            }
        }
    }
    
    @ChartContentBuilder
    private var chartSeries: some ChartContent {
        let _ = { print("🔍 chartContentForSegment called - Series:") }()
        ForEach(["groupedKeys"], id: \.self) { seriesName in
            let _ = { print("chartSeries", seriesName) }()

//            if let segments = vm.segmentsBySeries[seriesName] {
//
//                chartContentForSegments(segments: segments, seriesName: seriesName)
//            }
        }
        ForEach(points) { p in
            LineMark(x: .value("Date", p.date),
                     y: .value("Weight (kg)", p.value))
                .interpolationMethod(.monotone)
            
            PointMark(x: .value("Date", p.date),
                      y: .value("Weight (kg)", p.value))
                .symbol(Circle())
                .symbolSize(80)
                .foregroundStyle(.blue)
        }
    }
}


import SwiftUI
import Charts

struct WeightChart: View, Equatable {
    let points: [DataPoint]
    let visibleLength: TimeInterval
    let xScrollPosition: Date
    @Binding var selectedDate: Date?

    // Make “same enough” comparisons cheap to avoid recomputing body
    static func == (lhs: WeightChart, rhs: WeightChart) -> Bool {
        guard lhs.points.count == rhs.points.count,
              lhs.visibleLength == rhs.visibleLength,
              lhs.xScrollPosition == rhs.xScrollPosition else { return false }
        // Compare last point only (good heuristic)
        return lhs.points.last?.date == rhs.points.last?.date &&
               lhs.points.last?.value == rhs.points.last?.value
    }

    var body: some View {
        let _ = { print("🔍 chartContentForSegment called - yAxisBaseline:") }()
        Chart(points) { p in
            LineMark(x: .value("Date", p.date),
                     y: .value("Weight (kg)", p.value))
                .interpolationMethod(.monotone)

            // Avoid drawing markers for thousands of points (big perf win)
            PointMark(x: .value("Date", p.date),
                      y: .value("Weight (kg)", p.value))
                .symbol(Circle())
                .symbolSize(80)
        }
        .chartScrollableAxes(.horizontal)
        .chartScrollPosition(x: .constant(xScrollPosition)) // truly read-only
        .chartXSelection(value: $selectedDate)
        .chartXVisibleDomain(length: visibleLength)
    }
}
