//
//  Entry.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 04/07/25.
//


import SwiftUI
import Charts // Required for Chart views

//// Sample data structure
//struct Entry: Identifiable {
//    let id = UUID() // Unique identifier for ForEach
//    let x: Int // Represents a position on the x-axis, e.g., a bar index
//    let y: Double // Represents the value for the bar
//}
//
//// Sample array of data entries
//let sampleData: [Entry] = [
//    Entry(x: 0, y: 43),
//    Entry(x: 1, y: 53),
//    Entry(x: 2, y: 25),
//    Entry(x: 3, y: 43),
//    Entry(x: 4, y: 73),
//    Entry(x: 5, y: 24),
//    Entry(x: 6, y: 82),
//    Entry(x: 7, y: 37),
//    Entry(x: 8, y: 66),
//    Entry(x: 9, y: 33),
//    Entry(x: 10, y: 50),
//    Entry(x: 11, y: 60),
//    Entry(x: 12, y: 45),
//    Entry(x: 13, y: 70),
//    Entry(x: 14, y: 30),
//    Entry(x: 15, y: 90)
//]
//
//import SwiftUI
//import Charts // Don't forget to import Charts
//
//struct ScrollableChartView: View {
//    // State variable to hold the current scroll position for the x-axis
//    // Initialized to 0, which means the chart starts at the very beginning
//    @State private var xScrollPosition: Int = 0 // [6]
//
//    var body: some View {
//        VStack {
//            Text("Scrollable Bar Chart (iOS 17+)")
//                .font(.headline)
//                .padding()
//
//            Chart(sampleData) { entry in // [9]
//                BarMark(
//                    x: .value("Bar Index", entry.x), // X-axis represents the bar index
//                    y: .value("Value", entry.y)      // Y-axis represents the value
//                )
//                .foregroundStyle(entry.y > 50 ? .purple : .green) // Example styling [2]
//                .annotation(position: .top) { // Add annotation to display value [2]
//                    Text("\(Int(entry.y))")
//                        .font(.caption)
//                }
//            }
//            .chartScrollableAxes(.horizontal) // Make the chart scroll horizontally [2, 6]
//            .chartXVisibleDomain(length: 6) // Show 6 bars at a time [2, 5]
//            .chartScrollPosition(x: $xScrollPosition) // Bind the scroll position [6, 7]
//            .chartScrollTargetBehavior(.valueAligned(unit: 1)) // Snap to each individual bar [7]
//            .frame(height: 300) // Set a fixed height for the chart [2]
//            .padding()
//
//            // Display current scroll position
//            Text("Current X Scroll Position: \(xScrollPosition)")
//                .padding(.bottom)
//
//            // Button to jump to a specific bar (e.g., bar index 8)
//            Button("Scroll to Bar 8") {
//                // Setting the @State variable will programmatically scroll the chart
//                xScrollPosition = 8 // [9]
//            }
//            .buttonStyle(.borderedProminent)
//            .padding(.bottom)
//
//            Spacer()
//        }
//    }
//}
//
//// To preview the view in Xcode Canvas
//struct ScrollableChartView_Previews: PreviewProvider {
//    static var previews: some View {
//        ScrollableChartView()
//    }
//}



// MARK: - Line Chart for Last 2 Months (≈ 60 Days)

/// A data model suitable for date-based charts
struct DailyEntry: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

/// Generates 60 days of sample data ending today
private let lastSixtyDaysData: [DailyEntry] = {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    return (0..<1000).map { offset in
        let date = calendar.date(byAdding: .day, value: -offset, to: today)!
        return DailyEntry(date: date, value: Double.random(in: 20...100))
    }.reversed() // Oldest → Newest
}()

// +++++++++++++ Added helper modifier +++++++++++++
extension View {
    /// Adds week-aligned `chartScrollTargetBehavior` only when the API is available (iOS 17+/macOS 14+).
    @ViewBuilder
    func weekAlignedScroll() -> some View {
        if #available(iOS 17.0, macOS 14.0, *) {
            self
        } else {
            self
        }
    }
}

/// A horizontally scrollable line chart showing the previous ~2 months
struct ScrollableLineChartView: View {
    // Tracks horizontal position in the time domain – anchor at the current week's start
    private let calendar = Calendar.current
    @State private var xScrollDate: Date

    init() {
        // Anchor at the start of the current week (Mon)
        let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        let weekStart = calendar.date(from: comps) ?? Date()
        _xScrollDate = State(initialValue: weekStart)
    }

    var body: some View {
        VStack {
            Text("Weekly Line Chart – Scroll Through Weeks")
                .font(.headline)
                .padding()

            // Only feed the chart the data that overlaps a two-week window
            let endDate = calendar.date(byAdding: .day, value: 14, to: xScrollDate)!
            let visibleData = lastSixtyDaysData.filter { $0.date >= xScrollDate && $0.date < endDate }
            let showPoints = visibleData.count < 150 // avoid expensive dots for larger sets

            Chart(visibleData) { entry in
                LineMark(
                    x: .value("Date", entry.date),
                    y: .value("Value", entry.value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(.blue)

                if showPoints {
                    PointMark(
                        x: .value("Date", entry.date),
                        y: .value("Value", entry.value)
                    )
                    .symbolSize(25)
                }
            }
            // Horizontal scrolling
            .chartScrollableAxes(.horizontal)
            .chartXVisibleDomain(length: 7 * 24 * 60 * 60)
            .weekAlignedScroll() // Safe week snapping when API is available
            .chartScrollPosition(x: $xScrollDate)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                }
            }
            .frame(height: 300)
            .padding()

            // Week of reference shown to user
            Text("Week starting: \(xScrollDate.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption)
                .padding(.bottom)

            // Jump to current week button
            Button("Jump to Current Week") {
                xScrollDate = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom)

            Spacer()
        }
        // Keep scroll date within the available data range so the chart never shows empty future weeks
        .onChange(of: xScrollDate) { newStart in
            guard let earliest = lastSixtyDaysData.first?.date,
                  let latest = lastSixtyDaysData.last?.date else { return }

            // Align earliest/latest to week starts so we don't cut off weeks
            let earliestWeekStart = calendar.dateInterval(of: .weekOfYear, for: earliest)!.start
            let latestWeekStart = calendar.dateInterval(of: .weekOfYear, for: latest)!.start

            if newStart < earliestWeekStart {
                xScrollDate = earliestWeekStart
            } else if newStart > latestWeekStart {
                xScrollDate = latestWeekStart
            }
        }
    }
}

// MARK: - Preview
struct ScrollableLineChartView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollableLineChartView()
    }
}
