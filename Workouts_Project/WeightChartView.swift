//
//  WeightChartView.swift
//  Workouts_Project
//
//  Created by Assistant on 04/07/25.
//

import SwiftUI
import Charts

struct WeightChartView: View {
    let entries: [WeightEntry]
    @StateObject private var weekViewModel = WeekSectionViewModel()
    @StateObject private var monthViewModel = MonthSectionViewModel()
    @StateObject private var yearViewModel = YearSectionViewModel()
    @State private var selectedTimePeriod: TimePeriod = .week
    
    private var hasData: Bool {
        switch selectedTimePeriod {
        case .week:
            return !weekViewModel.chartPoints.isEmpty
        case .month:
            return !monthViewModel.chartPoints.isEmpty
        case .year:
            return !yearViewModel.chartPoints.isEmpty
        case .total:
            // For total view, use year view model data (monthly averages)
            return !yearViewModel.chartPoints.isEmpty
        }
    }
    
    // Debug computed property to check data flow
    private var debugInfo: String {
        switch selectedTimePeriod {
        case .week:
            return "Total entries: \(entries.count), Week chart points: \(weekViewModel.chartPoints.count)"
        case .month:
            return "Total entries: \(entries.count), Month chart points: \(monthViewModel.chartPoints.count)"
        case .year:
            return "Total entries: \(entries.count), Year chart points: \(yearViewModel.chartPoints.count)"
        case .total:
            return "Total entries: \(entries.count), Total chart points: \(yearViewModel.chartPoints.count)"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with current weight info
            weightInfoSection
            
            if hasData {
                // Chart
                chartSection
            } else {
                // Debug info and empty state
                VStack {
                    Text(debugInfo)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                    
                    emptyStateView
                }
            }
        }
        .onAppear {
            // Process entries for all view models on appear
            DispatchQueue.main.async {
                weekViewModel.processEntries(entries)
                monthViewModel.processEntries(entries)
                yearViewModel.processEntries(entries)
            }
        }
        .onChange(of: entries) { _, newEntries in
            // Process entries asynchronously to avoid UI blocking
            DispatchQueue.main.async {
                weekViewModel.processEntries(newEntries)
                monthViewModel.processEntries(newEntries)
                yearViewModel.processEntries(newEntries)
            }
        }
        .onChange(of: selectedTimePeriod) { _, newPeriod in
            #if DEBUG
            print("Changed time period to: \(newPeriod.displayName)")
            #endif
            
            // Only process entries if the chart points are empty
            // This preserves scroll position when switching between time periods
            DispatchQueue.main.async {
                switch newPeriod {
                case .week:
                    if weekViewModel.chartPoints.isEmpty {
                        weekViewModel.processEntries(entries)
                    }
                case .month:
                    if monthViewModel.chartPoints.isEmpty {
                        monthViewModel.processEntries(entries)
                    }
                case .year:
                    if yearViewModel.chartPoints.isEmpty {
                        yearViewModel.processEntries(entries)
                    }
                case .total:
                    // Use year view model for total view (monthly averages)
                    if yearViewModel.chartPoints.isEmpty {
                        yearViewModel.processEntries(entries)
                    }
                }
            }
        }
    }
    
    // MARK: - Weight Info Section
    @ViewBuilder
    private var weightInfoSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Display label based on selected time period
            Group {
                switch selectedTimePeriod {
                case .week:
                    Text(weekViewModel.weightDisplayLabel())
                case .month:
                    Text(monthViewModel.weightDisplayLabel())
                case .year:
                    Text(yearViewModel.weightDisplayLabel())
                case .total:
                    // For total, use year view model (monthly averages)
                    Text("All-Time Overview")
                }
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            .padding(.horizontal)
            
            HStack {
                // Display weight value based on selected time period
                Group {
                    switch selectedTimePeriod {
                    case .week:
                        Text(weekViewModel.weightDisplayValue())
                    case .month:
                        Text(monthViewModel.weightDisplayValue())
                    case .year:
                        Text(yearViewModel.weightDisplayValue())
                    case .total:
                        // For total, use year view model (monthly averages)
                        Text(yearViewModel.weightDisplayValue())
                    }
                }
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                
                Spacer()
                
                // Display selected point details based on selected time period
                switch selectedTimePeriod {
                case .week:
                    if let selectedPoint = weekViewModel.selectedPoint {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(weekViewModel.formatDate(selectedPoint.date))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if let bmi = selectedPoint.originalEntry.bmi {
                                Text("BMI: \(String(format: "%.1f", bmi / 10.0))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                case .month:
                    if let selectedPoint = monthViewModel.selectedPoint {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(monthViewModel.formatDate(selectedPoint.date))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if let bmi = selectedPoint.originalEntry.bmi {
                                Text("BMI: \(String(format: "%.1f", bmi / 10.0))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                case .year:
                    if let selectedPoint = yearViewModel.selectedPoint {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(yearViewModel.formatDate(selectedPoint.date))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if let bmi = selectedPoint.originalEntry.bmi {
                                Text("BMI: \(String(format: "%.1f", bmi / 10.0))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                case .total:
                    // For total, use year view model (monthly averages)
                    if let selectedPoint = yearViewModel.selectedPoint {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(yearViewModel.formatDate(selectedPoint.date))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if let bmi = selectedPoint.originalEntry.bmi {
                                Text("BMI: \(String(format: "%.1f", bmi / 10.0))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Chart Section
    
    // MARK: - Chart Helper Methods
    
    /// Returns whether a point is the currently selected point based on time period
    private func isPointSelected(_ point: WeightChartPoint) -> Bool {
        switch selectedTimePeriod {
        case .week:
            return weekViewModel.selectedPoint?.id == point.id
        case .month:
            return monthViewModel.selectedPoint?.id == point.id
        case .year:
            return yearViewModel.selectedPoint?.id == point.id
        case .total:
            return yearViewModel.selectedPoint?.id == point.id
        }
    }
    
    /// Returns the symbol size for a point based on selection state
    private func symbolSizeForPoint(_ point: WeightChartPoint) -> CGFloat {
        return isPointSelected(point) ? 100 : 50
    }
    
    // Custom axis value label view - kept for reference but no longer used directly
    private func createAxisLabel(for date: Date) -> some View {
        switch selectedTimePeriod {
        case .week:
            return Text(weekViewModel.formatWeekday(date))
                .font(.system(size: 9, weight: .medium))
                .fixedSize()
                .allowsHitTesting(false)
        case .month:
            return Text(monthViewModel.formatWeekday(date))
                .font(.system(size: 9, weight: .medium))
                .fixedSize()
                .allowsHitTesting(false)
        case .year:
            return Text(yearViewModel.formatMonthSingleLetter(date))
                .font(.system(size: 9, weight: .medium))
                .fixedSize()
                .allowsHitTesting(false)
        case .total:
            return Text(yearViewModel.formatMonth(date))
                .font(.system(size: 9, weight: .medium))
                .fixedSize()
                .allowsHitTesting(false)
        }
    }
    
    // MARK: - Chart Components
    
    // Line marks component for week view
    private var lineMarks: some ChartContent {
        ForEach(weekViewModel.chartPoints) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Weight", point.weight)
            )
            .lineStyle(StrokeStyle(lineWidth: 1.5))
            .foregroundStyle(.blue)
            .interpolationMethod(.linear) // Changed to linear for better performance
        }
    }
    
    // Point marks component for week view
    private var pointMarks: some ChartContent {
        ForEach(weekViewModel.getVisiblePoints()) { point in
            PointMark(
                x: .value("Date", point.date),
                y: .value("Weight", point.weight)
            )
            .foregroundStyle(.blue)
            .symbolSize(weekViewModel.selectedPoint?.id == point.id ? 80 : 40)
        }
    }
    
    // Selection indicator component for week view
    private var selectionMark: some ChartContent {
        let selectedDate = weekViewModel.selectedDate
        // Return the mark directly, it will only be visible if there's a selection
        return RuleMark(x: .value("Selected Date", selectedDate ?? Date()))
            .foregroundStyle(selectedDate != nil ? .gray.opacity(0.5) : .clear)
            .opacity(selectedDate != nil ? 1.0 : 0.0)
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            .zIndex(100)
    }
    
    // Custom X axis component for week view
    private var customXAxis: some AxisContent {
        AxisMarks(position: .bottom, values: .stride(by: .day)) { value in
            if let date = value.as(Date.self) {
                AxisValueLabel {
                    Text(weekViewModel.formatWeekday(date))
                        .font(.system(size: 9, weight: .medium))
                        .fixedSize()
                }
                
                AxisTick(stroke: StrokeStyle(lineWidth: 0.5))
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
            }
        }
    }
    
    // Main chart section - simplified version
    @ViewBuilder
    private var chartSection: some View {
        VStack(spacing: 16) {
            // Display the appropriate chart view based on selected time period
            Group {
                switch selectedTimePeriod {
                case .week:
                    weekChartView
                case .month:
                    monthChartView
                case .year:
                    yearChartView
                case .total:
                    totalChartView
                }
            }
            .frame(height: 200)
            
            // Time period segment control
            timePeriodSelector
        }
        .padding(.horizontal)
    }
    
    // MARK: - Week Chart View
    @ViewBuilder
    private var weekChartView: some View {
        GeometryReader { geometry in
            // Week chart
            Chart {
                // Line for all points
                ForEach(weekViewModel.chartPoints) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Weight", point.weight)
                    )
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                    .foregroundStyle(.blue)
                }
                
                // Only visible points
                ForEach(weekViewModel.getVisiblePoints()) { point in
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Weight", point.weight)
                    )
                    .foregroundStyle(.blue)
                    .symbolSize(weekViewModel.selectedPoint?.id == point.id ? 80 : 40)
                }
                
                // Selection indicator - directly included for simplicity
                if let selectedDate = weekViewModel.selectedDate {
                    RuleMark(x: .value("Selected Date", selectedDate))
                        .foregroundStyle(.gray.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                }
            }
            .chartXAxis {
                // Show axis marks for each day
                AxisMarks(values: .stride(by: .day)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(weekViewModel.formatWeekday(date))
                                .font(.system(size: 9))
                        }
                        AxisTick()
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                    }
                }
            }
            .chartYScale(domain: weekViewModel.weightRange.min...weekViewModel.weightRange.max)
            .chartYAxis {
                AxisMarks(position: .trailing) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                    AxisTick()
                    AxisValueLabel()
                }
            }
            .chartScrollableAxes(.horizontal)
            .chartXVisibleDomain(length: weekViewModel.visibleDomainLength)
            .chartScrollPosition(x: $weekViewModel.scrollPosition)
            .chartXSelection(value: Binding(
                get: { weekViewModel.selectedDate },
                set: { weekViewModel.selectPointAtDate($0) }
            ))
            .chartLegend(.hidden)
            .frame(width: geometry.size.width)
        }
    }
    
    // MARK: - Month Chart View Components
    
    // Month chart line marks
    private var monthLineMarks: some ChartContent {
        ForEach(monthViewModel.chartPoints) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Weight", point.weight)
            )
            .lineStyle(StrokeStyle(lineWidth: 1.5))
            .foregroundStyle(.blue)
        }
    }
    
    // Month chart point marks - only show points that are visible
    private var monthPointMarks: some ChartContent {
        ForEach(monthViewModel.getVisiblePoints()) { point in
            PointMark(
                x: .value("Date", point.date),
                y: .value("Weight", point.weight)
            )
            .foregroundStyle(.blue)
            .symbolSize(monthViewModel.selectedPoint?.id == point.id ? 80 : 40)
        }
    }
    
    // Month chart selection indicator
    private var monthSelectionMark: some ChartContent {
        let selectedDate = monthViewModel.selectedDate
        
        // Use a RuleMark with conditional styling - use transparent color when no selection
        return RuleMark(x: .value("Selected Date", selectedDate ?? Date()))
            .foregroundStyle(selectedDate != nil ? .gray.opacity(0.5) : .clear)
            .opacity(selectedDate != nil ? 1.0 : 0.0)
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            .zIndex(100)
    }
    
    // Month chart X axis configuration
    private var monthXAxis: some AxisContent {
        // Use explicit dates for weekly intervals instead of .weekOfMonth
        // This avoids the "Component is not supported" crash
        let weekInSeconds: TimeInterval = 7 * 24 * 60 * 60 // 7 days in seconds as TimeInterval (Double)
        
        return AxisMarks(preset: .aligned, values: .automatic(minimumStride: weekInSeconds)) { value in
            if let date = value.as(Date.self) {
                AxisValueLabel {
                    Text(monthViewModel.formatWeekday(date))
                        .font(.system(size: 9))
                }
                AxisTick()
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
            }
        }
    }
    
    // Month chart Y axis configuration
    private var monthYAxis: some AxisContent {
        AxisMarks(position: .trailing) { value in
            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
            AxisTick()
            AxisValueLabel()
        }
    }
    
    // MARK: - Month Chart View
    @ViewBuilder
    private var monthChartView: some View {
        GeometryReader { geometry in
            // Month chart with components separated to help the compiler
            Chart {
                monthLineMarks
                monthPointMarks
                monthSelectionMark
            }
            .chartXAxis(content: { monthXAxis })
            .chartYScale(domain: monthViewModel.weightRange.min...monthViewModel.weightRange.max)
            .chartYAxis(content: { monthYAxis })
            .chartScrollableAxes(.horizontal)
            .chartXVisibleDomain(length: monthViewModel.visibleDomainLength)
            // Using a binding wrapper to handle the Date? to Date conversion for chartScrollPosition
            .chartScrollPosition(x: Binding(
                get: { monthViewModel.scrollPosition ?? Date() },
                set: { monthViewModel.scrollPosition = $0 }
            ))
            .chartXSelection(value: Binding(
                get: { monthViewModel.selectedDate },
                set: { monthViewModel.selectPointAtDate($0) }
            ))
            .chartLegend(.hidden)
            .frame(width: geometry.size.width)
        }
    }
    
    // MARK: - Year Chart Components
    
    // Year chart line marks
    private var yearLineMarks: some ChartContent {
        ForEach(yearViewModel.chartPoints) { point in
            LineMark(
                x: .value("Month", point.date),
                y: .value("Weight", point.weight)
            )
            .lineStyle(StrokeStyle(lineWidth: 1.5))
            .foregroundStyle(.blue)
        }
    }
    
    // Year chart point marks - only show points that are visible
    private var yearPointMarks: some ChartContent {
        ForEach(yearViewModel.getVisiblePoints()) { point in
            PointMark(
                x: .value("Month", point.date),
                y: .value("Weight", point.weight)
            )
            .foregroundStyle(.blue)
            .symbolSize(yearViewModel.selectedPoint?.id == point.id ? 80 : 40)
        }
    }
    
    // Year chart selection indicator
    private var yearSelectionMark: some ChartContent {
        let selectedDate = yearViewModel.selectedDate
        
        return RuleMark(x: .value("Selected Month", selectedDate ?? Date()))
            .foregroundStyle(selectedDate != nil ? .gray.opacity(0.5) : .clear)
            .opacity(selectedDate != nil ? 1.0 : 0.0)
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            .zIndex(100)
    }
    
    // Year chart X axis configuration with month abbreviations
    private var yearXAxis: some AxisContent {
        // Use explicit month values to ensure all months are shown
        AxisMarks(values: .stride(by: .month)) { value in
            if let date = value.as(Date.self) {
                AxisValueLabel {
                    // Use single letter abbreviation for more consistent display
                    Text(yearViewModel.formatMonthSingleLetter(date))
                        .font(.system(size: 9, weight: .medium))
                }
                AxisTick()
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
            }
        }
    }
    
    // Year chart Y axis configuration
    private var yearYAxis: some AxisContent {
        AxisMarks(position: .trailing) { value in
            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
            AxisTick()
            AxisValueLabel()
        }
    }
    
    // MARK: - Year Chart View
    @ViewBuilder
    private var yearChartView: some View {
        GeometryReader { geometry in
            // Year chart with components
            Chart {
                yearLineMarks
                yearPointMarks
                yearSelectionMark
            }
            .chartXAxis(content: { yearXAxis })
            .chartYScale(domain: yearViewModel.weightRange.min...yearViewModel.weightRange.max)
            .chartYAxis(content: { yearYAxis })
            .chartScrollableAxes(.horizontal)
            .chartXVisibleDomain(length: yearViewModel.visibleDomainLength)
            .chartScrollPosition(x: Binding(
                get: { yearViewModel.scrollPosition ?? Date() },
                set: { yearViewModel.scrollPosition = $0 }
            ))
            .chartXSelection(value: Binding(
                get: { yearViewModel.selectedDate },
                set: { yearViewModel.selectPointAtDate($0) }
            ))
            .chartLegend(.hidden)
            .frame(width: geometry.size.width)
        }
    }
    
    // MARK: - Total Chart Components
    
    // Total chart line marks
    private var totalLineMarks: some ChartContent {
        ForEach(yearViewModel.chartPoints) { point in
            LineMark(
                x: .value("Month", point.date),
                y: .value("Weight", point.weight)
            )
            .lineStyle(StrokeStyle(lineWidth: 1.5))
            .foregroundStyle(.blue)
        }
    }
    
    // Total chart point marks
    private var totalPointMarks: some ChartContent {
        ForEach(yearViewModel.chartPoints) { point in
            PointMark(
                x: .value("Month", point.date),
                y: .value("Weight", point.weight)
            )
            .foregroundStyle(.blue)
            .symbolSize(yearViewModel.selectedPoint?.id == point.id ? 80 : 40)
        }
    }
    
    // Total chart selection indicator
    private var totalSelectionMark: some ChartContent {
        let selectedDate = yearViewModel.selectedDate
        
        return RuleMark(x: .value("Selected Month", selectedDate ?? Date()))
            .foregroundStyle(selectedDate != nil ? .gray.opacity(0.5) : .clear)
            .opacity(selectedDate != nil ? 1.0 : 0.0)
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            .zIndex(100)
    }
    
    // Total chart Y axis configuration - same as other charts
    private var totalYAxis: some AxisContent {
        AxisMarks(position: .trailing) { value in
            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
            AxisTick()
            AxisValueLabel()
        }
    }
    
    // MARK: - Total Chart View
    @ViewBuilder
    private var totalChartView: some View {
        GeometryReader { geometry in
            // Total chart - uses year data but without scrolling
            Chart {
                totalLineMarks
                totalPointMarks
                totalSelectionMark
            }
            // Hide X axis labels - only show grid lines
            .chartXAxis {
                AxisMarks { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                }
            }
            .chartYScale(domain: yearViewModel.weightRange.min...yearViewModel.weightRange.max)
            .chartYAxis(content: { totalYAxis })
            // No scroll - fit all points
            .chartXScale(domain: [yearViewModel.chartPoints.first?.date ?? Date(), yearViewModel.chartPoints.last?.date ?? Date()])
            .chartXSelection(value: Binding(
                get: { yearViewModel.selectedDate },
                set: { yearViewModel.selectPointAtDate($0) }
            ))
            .chartLegend(.hidden)
            .frame(width: geometry.size.width)
        }
    }
    
    // MARK: - Placeholder View
    @ViewBuilder
    private func placeholderView(for period: TimePeriod) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("\(period.displayName) View")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text("This chart type will be implemented soon")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Time Period Selector
    @ViewBuilder
    private var timePeriodSelector: some View {
        // Segment control
        Picker("Time Period", selection: $selectedTimePeriod) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Text(period.displayName).tag(period)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
    }
    // MARK: - Empty State
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Weight Data")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text("Weight entries will appear here when available")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 200)
        .padding()
    }
    

}

#Preview {
    WeightChartView(entries: [
        WeightEntry(
            operationType: "create",
            entryTimestamp: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-7*24*60*60)),
            serverTimestamp: "",
            weight: 7000, // 70.00 kg
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
    ])
    .padding()
}
