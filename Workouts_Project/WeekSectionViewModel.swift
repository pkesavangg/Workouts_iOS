//
//  WeekSectionViewModel.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 22/08/25.
//

import Foundation
import SwiftUI

@MainActor
class WeekSectionViewModel: ObservableObject {
    @Published var chartPoints: [WeightChartPoint] = []
    @Published var selectedPoint: WeightChartPoint?
    @Published var selectedDate: Date?
    @Published var scrollPosition: Date = Date()
    
    // Computed properties for chart data
    private(set) var weightRange: (min: Double, max: Double) = (0, 0)
    
    // Default to showing 7 days in the visible window
    var visibleDomainLength: TimeInterval {
        // Start with a default 7-day window
        let defaultLength: TimeInterval = 7 * 24 * 60 * 60
        
        // If we have enough data points, use the default window
        if chartPoints.count >= 3 {
            return defaultLength
        }
        
        // For fewer data points, ensure we show at least some space around them
        return max(defaultLength, 2.0 * 24 * 60 * 60) // At least 2 days
    }
    
    // Initialize with entries
    func processEntries(_ entries: [WeightEntry]) {
        // Process entries to get latest entry per day across all data
        let dailyPoints = getLatestEntryPerDay(entries)
        self.chartPoints = dailyPoints
        self.calculateWeightRange()
        self.scrollToLatestData()
    }
    
    // Select a point based on date
    func selectPointAtDate(_ date: Date?) {
        guard let date = date else {
            self.selectedPoint = nil
            self.selectedDate = nil
            return
        }
        
        self.selectedDate = date
        self.selectedPoint = chartPoints.min(by: { 
            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
        })
    }
    
    // Clear selection
    func clearSelection() {
        self.selectedPoint = nil
        self.selectedDate = nil
    }
    
    // Scroll to latest data
    func scrollToLatestData() {
        guard !chartPoints.isEmpty else { return }
        
        // Get the most recent date from chart points
        let latestDate = chartPoints.map({ $0.date }).max() ?? Date()
        scrollPosition = latestDate
    }
    
    // MARK: - Data Processing Methods
    
    /// Get the latest entry for each day across all available data
    private func getLatestEntryPerDay(_ entries: [WeightEntry]) -> [WeightChartPoint] {
        // Parse dates from all entries without filtering for specific time period
        let validEntries = entries.compactMap { entry -> (WeightEntry, Date)? in
            // Parse date using the robust parser
            guard let date = WeightChartDataManager.parseEntryDate(entry.entryTimestamp) else {
                return nil
            }
            
            // Include all entries with valid dates
            return (entry, date)
        }
        
        // Group entries by day (ignoring time component)
        var entriesByDay: [String: [(entry: WeightEntry, date: Date)]] = [:]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        for (entry, date) in validEntries {
            let dayKey = dateFormatter.string(from: date)
            if entriesByDay[dayKey] == nil {
                entriesByDay[dayKey] = []
            }
            entriesByDay[dayKey]?.append((entry, date))
        }
        
        // Get the latest entry for each day
        var latestEntriesPerDay: [WeightChartPoint] = []
        for (_, dayEntries) in entriesByDay {
            if let latestEntry = dayEntries.max(by: { $0.date < $1.date }) {
                // Create chart point from the latest entry of the day
                let point = WeightChartPoint(from: latestEntry.entry)
                latestEntriesPerDay.append(point)
            }
        }
        
        // Sort by date
        return latestEntriesPerDay.sorted { $0.date < $1.date }
    }
    
    /// Calculate weight range for Y-axis scaling
    private func calculateWeightRange() {
        guard !chartPoints.isEmpty else {
            weightRange = (0, 0)
            return
        }
        
        let weights = chartPoints.map { $0.weight }
        guard let minWeight = weights.min(), let maxWeight = weights.max() else {
            weightRange = (0, 0)
            return
        }
        
        // Add some padding to the range
        let padding = (maxWeight - minWeight) * 0.1
        weightRange = (
            max(0, minWeight - padding), // Don't go below 0
            maxWeight + padding
        )
    }
    
    // MARK: - Display Helpers
    
    /// Get the current weight display label
    func weightDisplayLabel() -> String {
        if selectedPoint != nil {
            return "Selected Weight"
        } else {
            // If most data is from within a week, show "This Week"
            let now = Date()
            let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
            
            let recentPoints = chartPoints.filter { $0.date >= oneWeekAgo }
            if recentPoints.count >= chartPoints.count / 2 {
                return "Average This Week"
            } else {
                return "Average Weight"
            }
        }
    }
    
    /// Get the current weight display value
    func weightDisplayValue() -> String {
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
    
    /// Format a date appropriately for display
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - WeightChartPoint Extension for Day-Only Date
extension WeightChartPoint {
    // Get just the day component of the date (without time)
    var dayOnlyDate: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return calendar.date(from: components) ?? date
    }
}
