//
//  YearSectionViewModel.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 22/08/25.
//

import Foundation
import SwiftUI
import Combine

class YearSectionViewModel: ObservableObject, WeightChartSectioning {
    @Published var chartPoints: [WeightChartPoint] = []
    @Published var selectedPoint: WeightChartPoint?
    @Published var selectedDate: Date?
    @Published var scrollPosition: Date?
    
    // Chart scaling properties
    var weightRange: (min: Double, max: Double) = (0, 100)
    
    // Date formatters
    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"  // Short month format (Jan, Feb, etc.)
        return formatter
    }()
    
    private let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"  // Month and year (Jan 2025, Feb 2025, etc.)
        return formatter
    }()
    
    // Calendar for date operations
    private let calendar = Calendar.autoupdatingCurrent
    
    /// Normalize a date to the first day of the month
    private func normalizeToMonth(_ date: Date) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? date
    }
    
    // For chart visible domain - show 12 months at a time
    var visibleDomainLength: TimeInterval {
        return 365 * 24 * 60 * 60 // Approximately one year
    }
    
    // MARK: - Public Methods
    
    func processEntries(_ entries: [WeightEntry]) {
        // Create a shared date formatter for month-year keys
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM" // Year-Month format for grouping
        
        // First, identify deleted timestamps
        var deletedTimestamps: Set<String> = []
        for entry in entries where entry.isDeleteOperation {
            deletedTimestamps.insert(entry.entryTimestamp)
        }
        
        // Filter valid entries (create operations with valid weight, not deleted)
        let validEntries = entries.filter { entry in
            entry.isCreateOperation && 
            entry.weight > 0 &&
            !deletedTimestamps.contains(entry.entryTimestamp)
        }
        
        // Group entries by month-year
        var entriesByMonth: [String: [WeightEntry]] = [:]
        
        for entry in validEntries {
            guard let date = WeightChartDataManager.parseEntryDate(entry.entryTimestamp) else {
                continue
            }
            
            let monthKey = dateFormatter.string(from: date)
            if entriesByMonth[monthKey] == nil {
                entriesByMonth[monthKey] = []
            }
            entriesByMonth[monthKey]!.append(entry)
        }
        
        // Calculate average weight for each month
        var monthlyPoints: [WeightChartPoint] = []
        
        for (monthKey, monthEntries) in entriesByMonth {
            // Calculate average weight for the month
            let totalWeight = monthEntries.reduce(0) { $0 + $1.weight }
            let averageWeight = Double(totalWeight) / Double(monthEntries.count)
            
            // Create date for the first day of the month
            if let monthDate = dateFormatter.date(from: monthKey) {
                // Create a representative entry for the month
                let firstEntry = monthEntries[0]
                let aggregatedEntry = WeightEntry(
                    operationType: "create",
                    entryTimestamp: ISO8601DateFormatter().string(from: monthDate),
                    serverTimestamp: "",
                    weight: Int(averageWeight),
                    bodyFat: nil,
                    muscleMass: nil,
                    boneMass: nil,
                    water: nil,
                    source: "aggregated",
                    bmi: monthEntries.compactMap { $0.bmi }.first,
                    impedance: nil,
                    pulse: nil,
                    unit: firstEntry.unit,
                    visceralFatLevel: nil,
                    subcutaneousFatPercent: nil,
                    proteinPercent: nil,
                    skeletalMusclePercent: nil,
                    bmr: nil,
                    metabolicAge: nil
                )
                
                let point = WeightChartPoint(from: aggregatedEntry, fallbackDate: monthDate)
                monthlyPoints.append(point)
            }
        }
        
        // Sort points by date
        monthlyPoints.sort { $0.date < $1.date }
        
        // Perform outlier detection only on older data (more than 3 months old)
        let recentCutoff = Date().addingTimeInterval(-90 * 24 * 60 * 60) // 3 months ago
        let (recentPoints, olderPoints) = monthlyPoints.reduce(into: ([WeightChartPoint](), [WeightChartPoint]())) { result, point in
            if point.date >= recentCutoff {
                result.0.append(point) // Recent points to preserve
            } else {
                result.1.append(point) // Older points to filter
            }
        }
        
        // Filter outliers only in the older points
        let filteredOlderPoints = WeightChartDataManager.filterOutliers(olderPoints)
        
        // Combine filtered older points with all recent points
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
                self.scrollPosition = lastDate
            }
            
            #if DEBUG
            print("📊 Year chart processed \(entries.count) entries into \(sortedFilteredPoints.count) monthly points")
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
        
        // Find the closest point to the selected date by month
        // For year view, we want to match to the start of the month
        let normalizedDate = normalizeToMonth(date)
        
        let closest = chartPoints.min { point1, point2 in
            let date1 = normalizeToMonth(point1.date)
            let date2 = normalizeToMonth(point2.date)
            
            return abs(date1.timeIntervalSince(normalizedDate)) < 
                   abs(date2.timeIntervalSince(normalizedDate))
        }
        
        selectedPoint = closest
    }
    
    // Get visible points for rendering - optimized for year view
    func getVisiblePoints() -> [WeightChartPoint] {
        // For year view, we typically have fewer points (one per month)
        // So it's more efficient and visually better to just show all points
        // This ensures all monthly data points are always visible
        if chartPoints.count < 100 {
            return chartPoints
        }
        
        // Return visible points based on current scrollPosition
        guard let currentPosition = scrollPosition else {
            return chartPoints
        }
        
        // Get visible date range with balanced padding on both sides
        let startDate = currentPosition.addingTimeInterval(-visibleDomainLength / 2)
        let endDate = currentPosition.addingTimeInterval(visibleDomainLength / 2)
        
        // Add extra padding (6 months) on each side to ensure smooth scrolling
        // This ensures points appear well before they enter the viewport
        let paddingInterval: TimeInterval = 180 * 24 * 60 * 60 // 6 months padding
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
    
    // Format a date as a month abbreviation (e.g., "Jan", "Feb", etc.)
    func formatMonth(_ date: Date) -> String {
        return monthFormatter.string(from: date)
    }
    
    // Format a date as a single-letter month abbreviation (e.g., "J", "F", etc.)
    func formatMonthSingleLetter(_ date: Date) -> String {
        let month = calendar.component(.month, from: date)
        // Single letters for months: J, F, M, A, M, J, J, A, S, O, N, D
        let monthLetters = ["", "J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"]
        return month >= 1 && month <= 12 ? monthLetters[month] : ""
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
            return "Selected Month Avg"
        } else if chartPoints.last != nil {
            return "Latest Month Avg"
        } else {
            return "Weight"
        }
    }
}

// MARK: - WeightChartSectioning
extension YearSectionViewModel {
    var preferredSelectedDate: Date? {
        if let selectedDate { return selectedDate }
        return chartPoints.last?.date
    }
}
