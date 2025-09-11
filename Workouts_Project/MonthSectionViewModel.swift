//
//  MonthSectionViewModel.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 22/08/25.
//

import Foundation
import SwiftUI
import Combine

class MonthSectionViewModel: ObservableObject, WeightChartSectioning {
    @Published var chartPoints: [WeightChartPoint] = []
    @Published var selectedPoint: WeightChartPoint?
    @Published var selectedDate: Date?
    @Published var scrollPosition: Date?
    
    // Chart scaling properties
    var weightRange: (min: Double, max: Double) = (0, 100)
    
    // Date formatters
    private let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM"
        return formatter
    }()
    
    private let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }()
    
    // Calendar for date operations - avoid Calendar component operations that could cause crashes
    private let calendar = Calendar.autoupdatingCurrent
    
    /// Normalize a date to midnight (00:00:00) of that day for consistent date handling
    private func normalizeToDay(_ date: Date) -> Date {
        // Use calendar to get start of day (midnight)
        return calendar.startOfDay(for: date)
    }
    
    // For chart visible domain
    var visibleDomainLength: TimeInterval {
        // Show 30 days at a time for month view
        // This controls how many days are visible in the viewport
        return 30 * 24 * 60 * 60
    }
    
    // Get dates for weekly markers (for x-axis labels)
    // This method is retained for API compatibility but we now use automatic axis marks
    var weeklyMarkerDates: [Date] {
        guard let firstDate = chartPoints.first?.date else { return [] }
        
        let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 60 * 60)
        let startDate = min(firstDate, thirtyDaysAgo)
        
        // Generate weekly marker dates with fixed time intervals to avoid calendar component issues
        var markerDates: [Date] = []
        let weekInterval: TimeInterval = 7 * 24 * 60 * 60 // exactly 7 days in seconds
        
        // Start from the provided date
        var currentMarker = startDate
        
        // Add weekly dates for 5 weeks
        for _ in 0..<5 {
            markerDates.append(currentMarker)
            currentMarker = currentMarker.addingTimeInterval(weekInterval)
        }
        
        return markerDates
    }
    
    // MARK: - Public Methods
    
    func processEntries(_ entries: [WeightEntry]) {
        // Process all entries for month view, matching the WeekSectionViewModel approach
        
        // Create a shared date formatter for better performance
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
        
        // Group valid entries by day (ignoring time component)
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
            guard let entry = entriesGroup.first(where: { $0.isCreateOperation }),
                  entry.weight > 0 else { continue }
            
            // Parse date using the robust parser
            guard let date = WeightChartDataManager.parseEntryDate(entry.entryTimestamp) else {
                continue
            }
            
            // Normalize the date to midnight for proper day alignment
            let normalizedDate = normalizeToDay(date)
            
            // Get day key
            let dayKey = dateFormatter.string(from: normalizedDate)
            
            // Update latest entry for this day if needed
            if let existingEntry = latestEntryByDay[dayKey] {
                // If we already have an entry for this day, use server timestamp to determine which is newer
                if let existingServerDate = WeightChartDataManager.parseEntryDate(existingEntry.entry.serverTimestamp),
                   let currentServerDate = WeightChartDataManager.parseEntryDate(entry.serverTimestamp),
                   currentServerDate > existingServerDate {
                    latestEntryByDay[dayKey] = (entry, normalizedDate)
                }
            } else {
                latestEntryByDay[dayKey] = (entry, normalizedDate)
            }
        }
        
        // Convert to chart points
        var points: [WeightChartPoint] = []
        points.reserveCapacity(latestEntryByDay.count) // Pre-allocate capacity
        
        for (_, entryData) in latestEntryByDay {
            // Create chart point with normalized date
            // Important: We need to use the fallbackDate constructor to ensure the date is properly normalized
            let point = WeightChartPoint(from: entryData.entry, fallbackDate: entryData.date)
            points.append(point)
        }
        
        // Sort by date
        points.sort { $0.date < $1.date }
        
        // Apply outlier detection and filtering but keep recent entries (last 7 days)
        
        // Identify recent points (last 7 days) that should be preserved
        let recentCutoff = Date().addingTimeInterval(-7 * 24 * 60 * 60) // 7 days ago
        let (recentPoints, olderPoints) = points.reduce(into: ([WeightChartPoint](), [WeightChartPoint]())) { result, point in
            if point.date >= recentCutoff {
                result.0.append(point) // Recent points to preserve
            } else {
                result.1.append(point) // Older points to filter
            }
        }
        
        // Filter outliers only in the older points
        let filteredOlderPoints = WeightChartDataManager.filterOutliers(olderPoints)
        
        // Combine filtered older points with all recent points (no filtering for recent)
        let filteredPoints = filteredOlderPoints + recentPoints
        
        // Sort again after combining
        let sortedFilteredPoints = filteredPoints.sorted { $0.date < $1.date }
        
        // Update chart points on the main thread
        DispatchQueue.main.async {
            self.chartPoints = sortedFilteredPoints
            
            // Set weight range for Y-axis scaling
            self.weightRange = WeightChartDataManager.getWeightRange(from: sortedFilteredPoints)
            
            // Set initial selected point to the most recent one
            self.selectedPoint = sortedFilteredPoints.last
            self.selectedDate = sortedFilteredPoints.last?.date
            
            // Set initial scroll position to show the most recent data
            if let lastDate = sortedFilteredPoints.last?.date {
                self.scrollPosition = lastDate // Position directly at latest date like WeekSectionViewModel
            }
            
            #if DEBUG
            print("📊 Month chart processed \(entries.count) entries into \(sortedFilteredPoints.count) points")
            #endif
        }
    }
    
    // Select a point at or near a given date
    func selectPointAtDate(_ date: Date?) {
        guard let date = date else {
            selectedPoint = nil
            selectedDate = nil
            return
        }
        
        selectedDate = date
        
        // Find the closest point to the selected date
        let closest = chartPoints.min { point1, point2 in
            abs(point1.date.timeIntervalSince(date)) < abs(point2.date.timeIntervalSince(date))
        }
        
        selectedPoint = closest
    }
    
    // Get visible points for rendering
    func getVisiblePoints() -> [WeightChartPoint] {
        // If we have a small number of points, just return all of them
        // This ensures all points are always visible in smaller datasets
        if chartPoints.count < 100 {
            return chartPoints
        }
        
        // Return visible points based on current scrollPosition
        guard let currentPosition = scrollPosition else {
            return chartPoints
        }
        
        // Get visible date range with balanced padding on both sides
        let halfDomainLength = visibleDomainLength / 2.0
        let startDate = currentPosition.addingTimeInterval(-halfDomainLength)
        let endDate = currentPosition.addingTimeInterval(halfDomainLength)
        
        // Add significant padding on both sides to ensure smooth scrolling and consistent point display
        // Using 30 days of padding to ensure points are visible well before they enter the viewport
        let paddingInterval: TimeInterval = 30 * 24 * 60 * 60 // 30 days padding
        let extendedStartDate = startDate.addingTimeInterval(-paddingInterval)
        let extendedEndDate = endDate.addingTimeInterval(paddingInterval)
        
        // Filter points that are in the extended visible range
        return chartPoints.filter { point in
            return point.date >= extendedStartDate && point.date <= extendedEndDate
        }
    }
    
    // Format a date for display
    func formatDate(_ date: Date) -> String {
        return fullDateFormatter.string(from: date)
    }
    
    // Format a date as a weekday
    func formatWeekday(_ date: Date) -> String {
        return weekdayFormatter.string(from: date)
    }
    
    // Get weight display value
    func weightDisplayValue() -> String {
        if let point = selectedPoint {
            let weight = point.weight
            let unit = point.originalEntry.unit ?? "kg"
            return String(format: "%.1f %@", weight, unit)
        } else if let lastPoint = chartPoints.last {
            let weight = lastPoint.weight
            let unit = lastPoint.originalEntry.unit ?? "kg"
            return String(format: "%.1f %@", weight, unit)
        } else {
            return "-- kg"
        }
    }
    
    // Get weight display label
    func weightDisplayLabel() -> String {
        if selectedPoint != nil {
            return "Selected Weight"
        } else if chartPoints.last != nil {
            return "Latest Weight"
        } else {
            return "Weight"
        }
    }

    // MARK: - WeightChartSectioning
    var preferredSelectedDate: Date? {
        if let selectedDate { return selectedDate }
        return chartPoints.last?.date
    }
}
