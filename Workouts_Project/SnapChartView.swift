import SwiftUI
import Charts
import SwiftUI
import Charts

// MARK: - Model
struct Stat: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

// MARK: - Custom Scroll Target (one page == one visible week)
struct WeekPagingScrollTargetBehavior: ChartScrollTargetBehavior {
    func updateTarget(_ target: inout ScrollTarget, context: ChartScrollTargetBehaviorContext) {
        let pageWidth = context.containerSize.width
        let fromX = context.originalTarget.rect.origin.x
        let toX   = target.rect.origin.x
        // Move exactly 1 page forward/back regardless of flick velocity
        target.rect.origin.x = toX > fromX ? fromX + pageWidth : fromX - pageWidth
    }
}

// MARK: - View
struct ChartDemoView: View {
    private let data: [Stat]
    private let weekLength: TimeInterval = 7 * 24 * 60 * 60
    @State private var scrollPositionX: Date = .now

    init() {
        // Dummy data: 120 days ending today, aligned to startOfDay
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let start = cal.date(byAdding: .day, value: -119, to: today)!

        var tmp: [Stat] = []
        for i in 0..<120 {
            let d = cal.date(byAdding: .day, value: i, to: start)!
            tmp.append(Stat(date: d, value: Double(Int.random(in: 0...10))))
        }
        self.data = tmp
    }

    var body: some View {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let weekStart = startOfWeek(for: today, weekday: 1) // Sunday start
        let weekEnd   = weekStart.addingTimeInterval(weekLength)
        let domainStart = (data.map { $0.date }.min() ?? weekStart)

        Group {
            if #available(iOS 17.0, *) {
                Chart {
                    ForEach(data) { s in
                        LineMark(
                            x: .value("Date", s.date, unit: .day),
                            y: .value("Value", s.value)
                        )
                        .cornerRadius(3)
                    }
                }
                .chartScrollableAxes(.horizontal)
                .chartXScale(domain: domainStart...weekEnd)
                .chartXVisibleDomain(length: weekLength)
                .chartScrollTargetBehavior(WeekPagingScrollTargetBehavior())
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisGridLine()
                        AxisTick()
                        if let date = value.as(Date.self) {
                            let label = date.formatted(.dateTime.weekday(.abbreviated)).lowercased()
                            AxisValueLabel { Text(label) }
                        }
                    }
                }
                .chartScrollTargetBehavior(WeekPagingScrollTargetBehavior())
                .chartScrollPosition(x: $scrollPositionX)
                .onAppear { scrollPositionX = weekEnd }
                .frame(height: 240)
            } else {
                Chart {
                    ForEach(data) { s in
                        LineMark(
                            x: .value("Date", s.date, unit: .day),
                            y: .value("Value", s.value)
                        )
                        .cornerRadius(3)
                    }
                }
                .chartScrollableAxes(.horizontal)
                .chartXScale(domain: domainStart...weekEnd)
                .chartXVisibleDomain(length: weekLength)
                .chartScrollTargetBehavior(WeekPagingScrollTargetBehavior())
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisGridLine()
                        AxisTick()
                        if let date = value.as(Date.self) {
                            let label = date.formatted(.dateTime.weekday(.abbreviated)).lowercased()
                            AxisValueLabel { Text(label) }
                        }
                    }
                }
                .chartScrollTargetBehavior(WeekPagingScrollTargetBehavior())
                .frame(height: 240)
                .padding()
            }
        }
    }

    // Align any date to the start of its week for a consistent initial window
    private func startOfWeek(for date: Date, weekday: Int = 2) -> Date {
        // weekday: 1=Sun, 2=Mon, ...
        let cal = Calendar.current
        let wd = cal.component(.weekday, from: date)
        let delta = (wd - weekday + 7) % 7
        return cal.startOfDay(for: cal.date(byAdding: .day, value: -delta, to: date)!)
    }
}

#Preview {
    ChartDemoView()
}
