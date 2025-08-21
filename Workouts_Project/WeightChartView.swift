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
    @State private var selectedPeriod: TimePeriod = .week
    @State private var selectedDate: Date?
    @State private var chartFrame: CGRect = .zero
    @State private var scrollPosition: Date = Date()
    
    // Cached data to prevent continuous recalculation
    @State private var cachedChartPoints: [WeightChartPoint] = []
    @State private var cachedPeriod: TimePeriod = .week
    @State private var cachedEntriesCount: Int = 0
    
    // Computed properties for chart data with caching
    private var filteredEntries: [WeightEntry] {
        WeightChartDataManager.filteredEntries(entries, for: selectedPeriod)
    }
    
    private var chartPoints: [WeightChartPoint] {
        // Use cache if data hasn't changed
        if cachedPeriod == selectedPeriod && cachedEntriesCount == entries.count && !cachedChartPoints.isEmpty {
            return cachedChartPoints
        }
        
        // Recalculate and cache with period-specific aggregation
        let newPoints = WeightChartDataManager.convertToChartPoints(filteredEntries, for: selectedPeriod)
        
        // Update cache on next frame to avoid view update during body computation
        DispatchQueue.main.async {
            cachedChartPoints = newPoints
            cachedPeriod = selectedPeriod
            cachedEntriesCount = entries.count
        }
        
        return newPoints
    }
    
    private var weightRange: (min: Double, max: Double) {
        WeightChartDataManager.getWeightRange(from: chartPoints)
    }
    
    private var hasData: Bool {
        !chartPoints.isEmpty
    }
    
    // Debug computed property to check data flow
    private var debugInfo: String {
        return "Total entries: \(entries.count), Filtered: \(filteredEntries.count), Chart points: \(chartPoints.count)"
    }
    
    // Selected point information
    private var selectedPoint: WeightChartPoint? {
        guard let selectedDate = selectedDate else { return nil }
        return chartPoints.min(by: { 
            abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate))
        })
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with current weight info
            weightInfoSection
            
            if hasData {
                // Chart
                chartSection
                
                // Time period selector
                TimePeriodSelector(selectedPeriod: $selectedPeriod)
                    .padding(.horizontal)
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
            scrollToLatestData()
        }
        .onChange(of: selectedPeriod) { _, _ in
            selectedDate = nil // Clear selection when period changes
            scrollToLatestData()
        }
        .onChange(of: chartPoints) { _, _ in
            // Reset chart position when data changes
            selectedDate = nil
            scrollToLatestData()
        }
    }
    
    // MARK: - Weight Info Section
    @ViewBuilder
    private var weightInfoSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(weightDisplayLabel)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            HStack {
                Text(weightDisplayValue)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let selectedPoint = selectedPoint {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formatDate(selectedPoint.date))
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
    @ViewBuilder
    private var chartSection: some View {
        Chart {
            // Main weight line
            ForEach(chartPoints) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Weight", point.weight)
                )
                .foregroundStyle(.blue)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.linear)
                
                // Data points
                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Weight", point.weight)
                )
                .foregroundStyle(.blue)
                .symbolSize(selectedPoint?.id == point.id ? 100 : 50)
            }
            
            // Selection indicator
            if let selectedDate = selectedDate {
                RuleMark(x: .value("Selected Date", selectedDate))
                    .foregroundStyle(.gray)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
            }
        }
        .chartYScale(domain: weightRange.min...weightRange.max)
        .chartScrollableAxes(getScrollableAxes())
        .chartXVisibleDomain(length: getVisibleDomainLength())
        .chartScrollPosition(x: $scrollPosition) // Instance method 'chartScrollPosition(x:)' requires that 'Date?' conform to 'Plottable'
        .chartXSelection(value: $selectedDate)
        .frame(height: 200)
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear {
                        chartFrame = geo.frame(in: .local)
                    }
                    .onChange(of: geo.frame(in: .local)) { _, newFrame in
                        chartFrame = newFrame
                    }
            }
        )
        .padding(.horizontal)
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
    
    // MARK: - Computed Properties
    
    private var weightDisplayLabel: String {
        if selectedPoint != nil {
            return "Selected Weight"
        } else {
            switch selectedPeriod {
            case .week:
                return "Average This Week"
            case .month:
                return "Average This Month"
            case .year:
                return "Average This Year"
            case .total:
                return "Overall Average"
            }
        }
    }
    
    private var weightDisplayValue: String {
        let weight: Double
        let unit = chartPoints.first?.originalEntry.unit ?? "kg"
        
        if let selectedPoint = selectedPoint {
            weight = selectedPoint.weight
        } else {
            // Calculate average
            let weights = chartPoints.map { $0.weight }
            weight = weights.isEmpty ? 0 : weights.reduce(0, +) / Double(weights.count)
        }
        
        return String(format: "%.1f %@", weight, unit)
    }
    
    // MARK: - Helper Methods
    
    private func scrollToLatestData() {
        guard !chartPoints.isEmpty else { return }
        
        // Get the most recent date from chart points
        let latestDate = chartPoints.map({ $0.date }).max() ?? Date()
        DispatchQueue.main.async {
            scrollPosition = latestDate
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        switch selectedPeriod {
        case .week, .month:
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
        case .year, .total:
            formatter.dateStyle = .long
            formatter.timeStyle = .none
        }
        return formatter.string(from: date)
    }
    
    private func getScrollableAxes() -> Axis.Set {
        switch selectedPeriod {
        case .week, .month, .year:
            return .horizontal
        case .total:
            return []
        }
    }
    

    private func getVisibleDomainLength() -> TimeInterval {
        switch selectedPeriod {
        case .week:
            return 7 * 24 * 60 * 60 // 7 days
        case .month:
            return 30 * 24 * 60 * 60 // 30 days
        case .year:
            return 90 * 24 * 60 * 60 // Show ~3 months at a time for year view
        case .total:
            // For total view, calculate the actual data range
            if !chartPoints.isEmpty {
                let dates = chartPoints.map { $0.date }
                if let minDate = dates.min(), let maxDate = dates.max() {
                    let range = maxDate.timeIntervalSince(minDate)
                    return range > 0 ? range : 365 * 24 * 60 * 60 // Default to 1 year if no range
                }
            }
            return 365 * 24 * 60 * 60 // Default to 1 year
        }
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
