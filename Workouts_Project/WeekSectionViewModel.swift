//
//  WeekSectionViewModel.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 22/08/25.
//

import Foundation
import SwiftUI

@MainActor
class WeekSectionViewModel: ObservableObject, WeightChartSectioning {
    @Published var chartPoints: [WeightChartPoint] = []
    @Published var selectedPoint: WeightChartPoint?
    @Published var selectedDate: Date?
    @Published var selectedInterpolatedWeight: Double?
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

    // MARK: - WeightChartSectioning
    var preferredSelectedDate: Date? {
        // Prefer the explicit selection if present; otherwise the latest point
        if let selectedDate { return selectedDate }
        return chartPoints.last?.date
    }
    
    // Select a point based on date (snap to day grid; interpolate at snapped date)
    func selectPointAtDate(_ date: Date?) {
        // Reset selection state first
        self.selectedPoint = nil
        self.selectedInterpolatedWeight = nil
        
        guard let date = date else {
            self.selectedDate = nil
            return
        }
        
        // Snap to the x-axis day grid (midnight of that day)
        let snapped = normalizeToDay(date)
        self.selectedDate = snapped
        
        // Compute interpolated weight at the selected position
        if let interpolated = interpolateWeight(at: snapped) {
            self.selectedInterpolatedWeight = interpolated
        }
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
        
        // Set scroll position to latest date
        scrollPosition = latestDate
        
        // Also select the latest point by default
        selectPointAtDate(latestDate)
        
        #if DEBUG
        print("📊 Scrolling to latest data: \(formatDate(latestDate))")
        print("📊 Total data points: \(chartPoints.count)")
        print("📊 Date range: \(formatDate(chartPoints.first?.date ?? Date())) - \(formatDate(latestDate))")
        #endif
    }
    
    // MARK: - Data Processing Methods
    
    /// Get the latest entry for each day across all available data
    private func getLatestEntryPerDay(_ entries: [WeightEntry]) -> [WeightChartPoint] {
        // Create a shared date formatter - reusing instead of creating multiple instances
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // First, group entries by their timestamp to identify deleted entries
        var entriesByTimestamp: [String: [WeightEntry]] = [:]
        for entry in entries {
            if entriesByTimestamp[entry.entryTimestamp] == nil {
                entriesByTimestamp[entry.entryTimestamp] = []
            }
            entriesByTimestamp[entry.entryTimestamp]!.append(entry)
        }
        
        // Group valid entries by day (ignoring time component) in a single pass
        var latestEntryByDay: [String: (entry: WeightEntry, date: Date)] = [:]
        
        for (timestamp, entriesGroup) in entriesByTimestamp {
            // Skip timestamps that have delete operations
            if entriesGroup.contains(where: { $0.isDeleteOperation }) {
                #if DEBUG
                print("🗑️ Skipping deleted entry with timestamp: \(timestamp)")
                #endif
                continue
            }
            
            // Find the create operation for this timestamp
            guard let entry = entriesGroup.first(where: { $0.isCreateOperation }) else { continue }
            
            // Parse date using the robust parser
            guard let date = WeightChartDataManager.parseEntryDate(entry.entryTimestamp) else {
                continue
            }
            
            // Process all dates - removed cutoff filter to show all historical data
            
            // Get day key
            let dayKey = dateFormatter.string(from: date)
            
            // Update latest entry for this day if needed
            if let existingEntry = latestEntryByDay[dayKey] {
                if date > existingEntry.date {
                    latestEntryByDay[dayKey] = (entry, date)
                }
            } else {
                latestEntryByDay[dayKey] = (entry, date)
            }
        }
        
        // Convert to chart points
        var chartPoints: [WeightChartPoint] = []
        chartPoints.reserveCapacity(latestEntryByDay.count) // Pre-allocate capacity to avoid resizing
        
        // Process all entries regardless of count - no limit
        for (_, entryData) in latestEntryByDay {
            // Normalize the date to midnight for proper day alignment
            let normalizedDate = normalizeToDay(entryData.date)
            
            // Create chart point with normalized date
            let point = WeightChartPoint(from: entryData.entry, fallbackDate: normalizedDate)
            chartPoints.append(point)
        }
        
        // Sort by date (limiting heap allocations by using in-place sort)
        chartPoints.sort { $0.date < $1.date }
        
        return chartPoints
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
        if selectedInterpolatedWeight != nil {
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
        
        if let interpolated = selectedInterpolatedWeight {
            weight = interpolated
        } else {
            // Calculate average
            let weights = chartPoints.map { $0.weight }
            weight = weights.isEmpty ? 0 : weights.reduce(0, +) / Double(weights.count)
        }
        
        return String(format: "%.1f %@", weight, unit)
    }
    
    // Shared date formatter for better performance
    private lazy var mediumDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    /// Format a date appropriately for display
    func formatDate(_ date: Date) -> String {
        return mediumDateFormatter.string(from: date)
    }
    
    // Shared calendar instance to avoid repeated calendar creations
    private let calendar: Calendar = Calendar.current
    
    // Cache for weekday letters
    private var weekdayLetters: [String] = ["", "Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
    
    /// Format a date to show just the weekday as a two-letter abbreviation (Su, Mo, Tu, We, Th, Fr, Sa)
    func formatWeekday(_ date: Date) -> String {
        // Get the weekday (1=Sunday, 2=Monday, ..., 7=Saturday)
        let weekday = calendar.component(.weekday, from: date)
        
        // Return from cached array for better performance
        return weekday >= 1 && weekday <= 7 ? weekdayLetters[weekday] : ""
    }
    
    /// Normalize a date to midnight (00:00:00) of that day
    func normalizeToDay(_ date: Date) -> Date {
        // Use shared calendar instance
        return calendar.startOfDay(for: date)
    }
    
    // Cached visible points to improve scroll performance
    private var cachedVisiblePoints: [WeightChartPoint] = []
    private var lastScrollPosition: Date = Date()
    
    /// Get only the points visible in the current chart view
    /// This optimizes rendering by only drawing points that are actually visible
    func getVisiblePoints() -> [WeightChartPoint] {
        guard !chartPoints.isEmpty else { return [] }
        
        // If we have fewer points, show all of them to ensure consistent display
        // Increased threshold to 50 to better handle typical weekly data volumes
        if chartPoints.count < 50 {
            return chartPoints
        }
        
        // Only recalculate visible points if scroll position has changed significantly
        // This improves scroll performance by reducing calculations during rapid scrolling
        let scrollDifference = abs(scrollPosition.timeIntervalSince(lastScrollPosition))
        if !cachedVisiblePoints.isEmpty && scrollDifference < 24*60*60 { // Full day difference threshold
            return cachedVisiblePoints
        }
        
        // Update last scroll position
        lastScrollPosition = scrollPosition
        
        // Calculate the visible date range based on scroll position
        let halfDomainLength = visibleDomainLength / 2.0
        let startDate = scrollPosition.addingTimeInterval(-halfDomainLength)
        let endDate = scrollPosition.addingTimeInterval(halfDomainLength)
        
        // Increase padding to ensure points appear before they enter the viewport
        // This helps with the issue of points only appearing during scroll
        let paddedStartDate = startDate.addingTimeInterval(-3*24*60*60) // 3 days of padding
        let paddedEndDate = endDate.addingTimeInterval(3*24*60*60)      // 3 days of padding
        
        // Binary search to find start and end indices for better performance with large datasets
        let startIndex = binarySearchForDateIndex(date: paddedStartDate, isLowerBound: true)
        let endIndex = binarySearchForDateIndex(date: paddedEndDate, isLowerBound: false)
        
        // Use slice to avoid copying the entire array
        if startIndex <= endIndex && startIndex < chartPoints.count {
            let visibleRange = max(0, startIndex)..<min(endIndex + 1, chartPoints.count)
            
            // Use all points in the visible range instead of sampling
            // This ensures all data points are displayed consistently
            cachedVisiblePoints = Array(chartPoints[visibleRange])
            
            // Always include the selected point if there is one and it's not already included
            if let selectedPoint = selectedPoint, !cachedVisiblePoints.contains(where: { $0.id == selectedPoint.id }) {
                cachedVisiblePoints.append(selectedPoint)
            }
            
            return cachedVisiblePoints
        }
        
        return []
    }
    
    /// Check if a specific point is visible in the current view
    /// This helps optimize rendering by only drawing point marks for visible points
    func isPointVisible(_ point: WeightChartPoint) -> Bool {
        // If we have very few points, all are visible
        if chartPoints.count < 20 {
            return true
        }
        
        // Calculate the visible date range based on scroll position
        let halfDomainLength = visibleDomainLength / 2.0
        let startDate = scrollPosition.addingTimeInterval(-halfDomainLength)
        let endDate = scrollPosition.addingTimeInterval(halfDomainLength)
        
        // Add padding for better visual experience
        let paddedStartDate = startDate.addingTimeInterval(-24*60*60 * 2)
        let paddedEndDate = endDate.addingTimeInterval(24*60*60 * 2)
        
        return point.date >= paddedStartDate && point.date <= paddedEndDate
    }
    
    /// Binary search to find the closest index for a date
    /// This is much faster than filtering the entire array
    private func binarySearchForDateIndex(date: Date, isLowerBound: Bool) -> Int {
        guard !chartPoints.isEmpty else { return 0 }
        
        var low = 0
        var high = chartPoints.count - 1
        
        while low <= high {
            let mid = (low + high) / 2
            let midDate = chartPoints[mid].date
            
            if midDate < date {
                low = mid + 1
            } else if midDate > date {
                high = mid - 1
            } else {
                return mid
            }
        }
        
        // When we exit the loop, low > high
        // For lower bound, return high (largest date <= target)
        // For upper bound, return low (smallest date >= target)
        return isLowerBound ? high : low
    }

    /// Interpolates the weight value at an arbitrary date between two neighboring chart points.
    private func interpolateWeight(at date: Date) -> Double? {
        guard !chartPoints.isEmpty else { return nil }
        
        // Find bounding indices around the selected date
        let lowerIndex = binarySearchForDateIndex(date: date, isLowerBound: true)
        let upperIndex = binarySearchForDateIndex(date: date, isLowerBound: false)
        
        // If before first point or after last point, clamp to nearest endpoint
        if lowerIndex < 0, let first = chartPoints.first { return first.weight }
        if upperIndex >= chartPoints.count, let last = chartPoints.last { return last.weight }
        
        // Indices should now be within bounds
        guard lowerIndex >= 0, upperIndex < chartPoints.count else { return nil }
        let lowerPoint = chartPoints[lowerIndex]
        let upperPoint = chartPoints[upperIndex]
        
        // If exactly on a point
        if lowerIndex == upperIndex {
            self.selectedPoint = lowerPoint
            return lowerPoint.weight
        }
        
        let t0 = lowerPoint.date.timeIntervalSinceReferenceDate
        let t1 = upperPoint.date.timeIntervalSinceReferenceDate
        let t = date.timeIntervalSinceReferenceDate
        
        if t1 <= t0 { return lowerPoint.weight }
        let ratio = max(0.0, min(1.0, (t - t0) / (t1 - t0)))
        
        let w0 = lowerPoint.weight
        let w1 = upperPoint.weight
        return w0 + ratio * (w1 - w0)
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
