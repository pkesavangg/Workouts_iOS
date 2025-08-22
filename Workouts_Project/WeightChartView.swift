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
    @StateObject private var viewModel = WeekSectionViewModel()
    @State private var selectedTimePeriod: TimePeriod = .week
    
    private var hasData: Bool {
        !viewModel.chartPoints.isEmpty
    }
    
    // Debug computed property to check data flow
    private var debugInfo: String {
        return "Total entries: \(entries.count), Chart points: \(viewModel.chartPoints.count)"
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
            // Process entries once on appear
            DispatchQueue.main.async {
                viewModel.processEntries(entries)
            }
        }
        .onChange(of: entries) { _, newEntries in
            // Process entries asynchronously to avoid UI blocking
            DispatchQueue.main.async {
                viewModel.processEntries(newEntries)
            }
        }
        .onChange(of: selectedTimePeriod) { _, newPeriod in
            #if DEBUG
            print("Changed time period to: \(newPeriod.displayName)")
            #endif
            
            // We only need to process entries for the week view for now
            // In the future, you'll use different viewModels for each time period
            if newPeriod == .week {
                viewModel.processEntries(entries)
            }
            // When you implement other views, you'll add more cases here
            // Example:
            // case .month: monthViewModel.processEntries(entries)
            // case .year: yearViewModel.processEntries(entries)
            // case .total: totalViewModel.processEntries(entries)
        }
    }
    
    // MARK: - Weight Info Section
    @ViewBuilder
    private var weightInfoSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.weightDisplayLabel())
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            HStack {
                Text(viewModel.weightDisplayValue())
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let selectedPoint = viewModel.selectedPoint {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(viewModel.formatDate(selectedPoint.date))
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
            .padding(.horizontal)
        }
    }
    
    // MARK: - Chart Section
    
    // MARK: - Chart Helper Methods
    
    /// Returns whether a point is the currently selected point
    private func isPointSelected(_ point: WeightChartPoint) -> Bool {
        return viewModel.selectedPoint?.id == point.id
    }
    
    /// Returns the symbol size for a point based on selection state
    private func symbolSizeForPoint(_ point: WeightChartPoint) -> CGFloat {
        return isPointSelected(point) ? 100 : 50
    }
    
    // Custom axis value label view - kept for reference but no longer used directly
    private func createAxisLabel(for date: Date) -> some View {
        Text(viewModel.formatWeekday(date))
            .font(.system(size: 9, weight: .medium))
            .fixedSize()
            .allowsHitTesting(false)
    }
    
    // MARK: - Chart Components
    
    // Line marks component
    private var lineMarks: some ChartContent {
        ForEach(viewModel.chartPoints) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Weight", point.weight)
            )
            .lineStyle(StrokeStyle(lineWidth: 1.5))
            .foregroundStyle(.blue)
            .interpolationMethod(.linear) // Changed to linear for better performance
        }
    }
    
    // Point marks component
    private var pointMarks: some ChartContent {
        ForEach(viewModel.getVisiblePoints()) { point in
            PointMark(
                x: .value("Date", point.date),
                y: .value("Weight", point.weight)
            )
            .foregroundStyle(.blue)
            .symbolSize(viewModel.selectedPoint?.id == point.id ? 80 : 40)
        }
    }
    
    // Selection indicator component - simplified without using Group
    private var selectionMark: some ChartContent {
        let selectedDate = viewModel.selectedDate
        // Return the mark directly, it will only be visible if there's a selection
        return RuleMark(x: .value("Selected Date", selectedDate ?? Date()))
            .foregroundStyle(selectedDate != nil ? .gray.opacity(0.5) : .clear)
            .opacity(selectedDate != nil ? 1.0 : 0.0)
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            .zIndex(100)
    }
    
    // Custom X axis component
    private var customXAxis: some AxisContent {
        AxisMarks(position: .bottom, values: .stride(by: .day)) { value in
            if let date = value.as(Date.self) {
                AxisValueLabel {
                    Text(viewModel.formatWeekday(date))
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
                    monthChartPlaceholderView
                case .year:
                    yearChartPlaceholderView
                case .total:
                    totalChartPlaceholderView
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
                ForEach(viewModel.chartPoints) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Weight", point.weight)
                    )
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                    .foregroundStyle(.blue)
                }
                
                // Only visible points
                ForEach(viewModel.getVisiblePoints()) { point in
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Weight", point.weight)
                    )
                    .foregroundStyle(.blue)
                    .symbolSize(viewModel.selectedPoint?.id == point.id ? 80 : 40)
                }
                
                // Selection indicator - directly included for simplicity
                if let selectedDate = viewModel.selectedDate {
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
                            Text(viewModel.formatWeekday(date))
                                .font(.system(size: 9))
                        }
                        AxisTick()
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                    }
                }
            }
            .chartYScale(domain: viewModel.weightRange.min...viewModel.weightRange.max)
            .chartYAxis {
                AxisMarks(position: .trailing) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                    AxisTick()
                    AxisValueLabel()
                }
            }
            .chartScrollableAxes(.horizontal)
            .chartXVisibleDomain(length: viewModel.visibleDomainLength)
            .chartScrollPosition(x: $viewModel.scrollPosition)
            .chartXSelection(value: Binding(
                get: { viewModel.selectedDate },
                set: { viewModel.selectPointAtDate($0) }
            ))
            .chartLegend(.hidden)
            .frame(width: geometry.size.width)
        }
    }
    
    // MARK: - Month Chart Placeholder
    @ViewBuilder
    private var monthChartPlaceholderView: some View {
        placeholderView(for: .month)
    }
    
    // MARK: - Year Chart Placeholder
    @ViewBuilder
    private var yearChartPlaceholderView: some View {
        placeholderView(for: .year)
    }
    
    // MARK: - Total Chart Placeholder
    @ViewBuilder
    private var totalChartPlaceholderView: some View {
        placeholderView(for: .total)
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
