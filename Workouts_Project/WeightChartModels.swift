//
//  WeightChartModels.swift
//  Workouts_Project
//
//  Created by Assistant on 04/07/25.
//

import Foundation

// MARK: - Time Period Selection
enum TimePeriod: String, CaseIterable {
    case week = "1W"
    case month = "1M"
    case year = "1Y"
    case total = "All"
    
    var displayName: String {
        return self.rawValue
    }
    
    var timeInterval: TimeInterval {
        switch self {
        case .week:
            return 7 * 24 * 60 * 60 // 7 days
        case .month:
            return 30 * 24 * 60 * 60 // 30 days
        case .year:
            return 365 * 24 * 60 * 60 // 365 days
        case .total:
            return .greatestFiniteMagnitude // All time
        }
    }
}

// MARK: - Chart Data Point
struct WeightChartPoint: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let weight: Double
    let originalEntry: WeightEntry
    
    init(from entry: WeightEntry) {
        self.originalEntry = entry
        
        // Parse date from entry timestamp using robust parsing
        self.date = WeightChartDataManager.parseEntryDate(entry.entryTimestamp) ?? Date()
        
        // Convert weight from Int (stored as grams * 100) to Double (kg or lbs)
        self.weight = Double(entry.weight) / 10.0
    }
    
    init(from entry: WeightEntry, fallbackDate: Date) {
        self.originalEntry = entry
        self.date = fallbackDate
        self.weight = Double(entry.weight) / 10.0
    }
    
    // Equatable conformance
    static func == (lhs: WeightChartPoint, rhs: WeightChartPoint) -> Bool {
        return lhs.id == rhs.id &&
               lhs.date == rhs.date &&
               lhs.weight == rhs.weight &&
               lhs.originalEntry.entryTimestamp == rhs.originalEntry.entryTimestamp
    }
}

// MARK: - Chart Data Manager
class WeightChartDataManager {
    // Cached formatters for better performance
    private static let iso8601FormatterWithFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    private static let iso8601FormatterStandard: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
    
    private static let calendar = Calendar.current
    
    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()
    
    /// Robust date parsing that handles multiple ISO 8601 variations
    static func parseEntryDate(_ timestamp: String) -> Date? {
        // Strategy 1: Try simple ISO8601DateFormatter first - use cached instance
        if let date = iso8601FormatterWithFractional.date(from: timestamp) {
            return date
        }
        
        // Try without fractional seconds - use cached instance
        if let date = iso8601FormatterStandard.date(from: timestamp) {
            return date
        }
        
        // Strategy 2: Manual DateFormatter for various patterns
        let manualFormatter = DateFormatter()
        manualFormatter.timeZone = TimeZone(abbreviation: "UTC")
        manualFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        // Common patterns to try
        let patterns = [
            // ISO 8601 with milliseconds
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZ",
            
            // ISO 8601 without milliseconds
            "yyyy-MM-dd'T'HH:mm:ss'Z'",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ssZZZZ",
            
            // Alternative formats
            "yyyy-MM-dd'T'HH:mm:ss.SSS",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd HH:mm:ss",
            
            // Edge cases
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'", // 6 digit microseconds
            "yyyy-MM-dd'T'HH:mm:ss.SSSS'Z'",   // 4 digit milliseconds
        ]
        
        for pattern in patterns {
            manualFormatter.dateFormat = pattern
            if let date = manualFormatter.date(from: timestamp) {
                return date
            }
        }
        
        #if DEBUG
        print("🔍 All parsing attempts failed for timestamp: '\(timestamp)'")
        #endif
        
        return nil
    }
    
    /// Returns all entries regardless of period (filtering now handled by chart view domain)
    static func filteredEntries(_ entries: [WeightEntry], for period: TimePeriod, from referenceDate: Date = Date()) -> [WeightEntry] {
        // Return all entries - let the chart handle the visible domain
        return entries
    }
    
    /// Create chart point with fallback date estimation when parsing fails
    static func WeightChartPointWithFallbackDate(from entry: WeightEntry, fallbackIndex: Int, totalEntries: Int) -> WeightChartPoint {
        // Strategy: distribute failed entries evenly across the last 30 days
        let now = Date()
        let thirtyDaysAgo = now.addingTimeInterval(-30 * 24 * 60 * 60)
        
        // Calculate fallback date based on index position
        let timeRange = now.timeIntervalSince(thirtyDaysAgo)
        let positionRatio = Double(fallbackIndex) / Double(max(totalEntries - 1, 1))
        let fallbackInterval = timeRange * positionRatio
        let fallbackDate = thirtyDaysAgo.addingTimeInterval(fallbackInterval)
        
        #if DEBUG
        print("📅 Created fallback date \(fallbackDate) for entry \(fallbackIndex)/\(totalEntries)")
        #endif
        
        return WeightChartPoint(from: entry, fallbackDate: fallbackDate)
    }
    
    /// Debug date parsing to identify failures
    static func debugDateParsing(_ entries: [WeightEntry]) {
        #if DEBUG
        print("🔍 Debugging date parsing for \(entries.count) entries:")
        var failedCount = 0
        for (index, entry) in entries.enumerated().prefix(20) { // Limit to first 20 for readability
            let parsed = parseEntryDate(entry.entryTimestamp)
            let status = parsed != nil ? "✅" : "❌"
            print("\(status) Entry \(index): '\(entry.entryTimestamp)' -> \(parsed?.description ?? "FAILED")")
            if parsed == nil {
                failedCount += 1
                print("   Weight: \(entry.weight), Source: \(entry.source)")
            }
        }
        if entries.count > 20 {
            print("... and \(entries.count - 20) more entries")
        }
        print("📊 Total failed parsing: \(failedCount)/\(entries.count)")
        #endif
    }
    
    /// Converts WeightEntry array to chart points with aggregation for month/year/total periods
    static func convertToChartPoints(_ entries: [WeightEntry], for period: TimePeriod = .week) -> [WeightChartPoint] {
        // For week view, show individual entries
        if period == .week {
            return convertToIndividualChartPoints(entries)
        } else {
            // For month, year, and total views, aggregate by month
            return convertToAggregatedChartPoints(entries)
        }
    }
    
    /// Converts WeightEntry array to individual chart points (for week view)
    private static func convertToIndividualChartPoints(_ entries: [WeightEntry]) -> [WeightChartPoint] {
        // Only keep essential logging
        #if DEBUG
        if entries.count > 100 {
            print("🔍 Converting \(entries.count) entries to chart points (large dataset)")
        }
        #endif
        
        // Filter valid entries (only create operations with valid weight)
        let validEntries = entries.filter { entry in
            entry.isCreateOperation && entry.weight > 0
        }
        
        #if DEBUG
        print("📊 Raw weight data analysis:")
        let weights = validEntries.prefix(10).map { Double($0.weight) / 100.0 }
        print("   Sample weights (kg): \(weights)")
        print("   Units from entries: \(Set(validEntries.prefix(10).map { $0.unit }))")
        #endif
        
        // Convert entries to chart points with fallback handling
        var fallbackCount = 0
        let chartPoints: [WeightChartPoint] = validEntries.enumerated().compactMap { (index, entry) -> WeightChartPoint? in
            // Parse date with fallback
            if parseEntryDate(entry.entryTimestamp) != nil {
                return WeightChartPoint(from: entry)
            } else {
                fallbackCount += 1
                #if DEBUG
                if fallbackCount <= 5 { // Only print first 5 to avoid spam
                    print("⚠️ Failed to parse date: '\(entry.entryTimestamp)' - using fallback date estimation")
                }
                #endif
                // Fallback: estimate date based on position in sorted array
                return WeightChartPointWithFallbackDate(from: entry, fallbackIndex: index, totalEntries: validEntries.count)
            }
        }
        
        // Sort chronologically
        let sortedChartPoints = chartPoints.sorted { $0.date < $1.date }
        
        // Apply outlier detection and filtering
        let filteredChartPoints = filterOutliers(sortedChartPoints)
        
        #if DEBUG
        let successfulParsing = chartPoints.count - fallbackCount
        let outliersRemoved = sortedChartPoints.count - filteredChartPoints.count
        print("📊 Chart conversion summary:")
        print("   Total entries: \(entries.count)")
        print("   Valid entries (create + weight > 0): \(validEntries.count)")
        print("   Successful date parsing: \(successfulParsing)")
        print("   Fallback dates used: \(fallbackCount)")
        print("   Outliers removed: \(outliersRemoved)")
        print("   Final chart points: \(filteredChartPoints.count)")
        if fallbackCount > 0 {
            print("   ✅ Rescued \(fallbackCount) entries that would have been excluded!")
        }
        if outliersRemoved > 0 {
            print("   🧹 Filtered \(outliersRemoved) outliers for better chart appearance!")
        }
        #endif
        
        return filteredChartPoints
    }
    
    /// Converts WeightEntry array to aggregated monthly chart points (for month/total views)
    private static func convertToAggregatedChartPoints(_ entries: [WeightEntry]) -> [WeightChartPoint] {
        #if DEBUG
        print("🗓️ Converting to monthly aggregated chart points...")
        #endif
        
        // Filter valid entries
        let validEntries = entries.filter { entry in
            entry.isCreateOperation && entry.weight > 0
        }
        
        // Group entries by month-year
        var monthlyGroups: [String: [WeightEntry]] = [:]
        // Use cached month formatter
        
        for entry in validEntries {
            if let date = parseEntryDate(entry.entryTimestamp) {
                let monthKey = monthFormatter.string(from: date)
                monthlyGroups[monthKey, default: []].append(entry)
            }
        }
        
        // Create aggregated chart points for each month
        var aggregatedPoints: [WeightChartPoint] = []
        
        for (monthKey, monthEntries) in monthlyGroups {
            guard !monthEntries.isEmpty else { continue }
            
            // Calculate average weight for the month
            let totalWeight = monthEntries.reduce(0) { $0 + $1.weight }
            let averageWeight = Double(totalWeight) / Double(monthEntries.count)
            
            // Use the start date of the month for proper x-axis alignment
            if let monthDate = monthFormatter.date(from: monthKey) {
                let startOfMonth = calendar.dateInterval(of: .month, for: monthDate)?.start ?? monthDate
                
                // Create a representative entry for the month
                let firstEntry = monthEntries[0]
                let aggregatedEntry = WeightEntry(
                    operationType: "create",
                    entryTimestamp: ISO8601DateFormatter().string(from: startOfMonth),
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
                
                let chartPoint = WeightChartPoint(from: aggregatedEntry, fallbackDate: startOfMonth)
                aggregatedPoints.append(chartPoint)
                
                #if DEBUG
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MMM d, yyyy"
                print("📊 Month \(monthKey): \(monthEntries.count) entries → avg \(String(format: "%.1f", averageWeight / 100.0)) \(firstEntry.unit ?? "kg") at \(dateFormatter.string(from: startOfMonth))")
                #endif
            }
        }
        
        // Sort by date
        let sortedPoints = aggregatedPoints.sorted { $0.date < $1.date }
        
        #if DEBUG
        print("📊 Created \(sortedPoints.count) monthly aggregated points from \(validEntries.count) entries")
        #endif
        
        return sortedPoints
    }
    
    /// Filter outliers to improve chart appearance and remove obvious data errors
    static func filterOutliers(_ points: [WeightChartPoint]) -> [WeightChartPoint] {
        guard points.count > 2 else { return points }
        
        let weights = points.map { $0.weight }
        
        #if DEBUG
        print("🔍 Outlier detection analysis:")
        print("   Weight range: \(weights.min() ?? 0) - \(weights.max() ?? 0)")
        print("   Sample weights: \(weights.prefix(5).map { String(format: "%.1f", $0) })")
        #endif
        
        // Method 1: Remove obviously impossible weights (human weight boundaries)
        let humanWeightFiltered = points.filter { point in
            let weight = point.weight
            // Reasonable human weight range: 2-200 kg (4.4-440 lbs)
            return weight >= 2.0 && weight <= 200.0
        }
        
        // Method 2: Statistical outlier detection using IQR method
        let sortedWeights = weights.sorted()
        let q1Index = sortedWeights.count / 4
        let q3Index = (sortedWeights.count * 3) / 4
        
        let q1 = sortedWeights[q1Index]
        let q3 = sortedWeights[q3Index]
        let iqr = q3 - q1
        let lowerBound = q1 - 1.5 * iqr
        let upperBound = q3 + 1.5 * iqr
        
        let statisticalFiltered = humanWeightFiltered.filter { point in
            let weight = point.weight
            return weight >= lowerBound && weight <= upperBound
        }
        
        // Method 3: Remove dramatic consecutive changes (likely unit conversion errors)
        var finalFiltered: [WeightChartPoint] = []
        for (index, point) in statisticalFiltered.enumerated() {
            if index == 0 {
                finalFiltered.append(point)
            } else {
                let previousWeight = finalFiltered.last!.weight
                let currentWeight = point.weight
                let percentChange = abs(currentWeight - previousWeight) / previousWeight
                
                // Skip points with >50% weight change (likely data errors)
                if percentChange <= 0.5 {
                    finalFiltered.append(point)
                } else {
                    #if DEBUG
                    print("   🚫 Filtered dramatic change: \(String(format: "%.1f", previousWeight)) → \(String(format: "%.1f", currentWeight)) (\(String(format: "%.0f", percentChange * 100))% change)")
                    #endif
                }
            }
        }
        
        #if DEBUG
        let removed = points.count - finalFiltered.count
        if removed > 0 {
            print("   📊 Outlier filtering results:")
            print("      Human weight filter: \(points.count) → \(humanWeightFiltered.count)")
            print("      Statistical filter (IQR): \(humanWeightFiltered.count) → \(statisticalFiltered.count)")
            print("      Dramatic change filter: \(statisticalFiltered.count) → \(finalFiltered.count)")
            print("      Total removed: \(removed) outliers")
        }
        #endif
        
        return finalFiltered
    }
    
    /// Gets the weight range for Y-axis scaling
    static func getWeightRange(from points: [WeightChartPoint]) -> (min: Double, max: Double) {
        guard !points.isEmpty else { return (0, 100) }
        
        let weights = points.map { $0.weight }
        let minWeight = weights.min() ?? 0
        let maxWeight = weights.max() ?? 100
        
        // Add some padding (10% on each side)
        let padding = (maxWeight - minWeight) * 0.1
        let paddedMin = max(0, minWeight - padding)
        let paddedMax = maxWeight + padding
        
        return (paddedMin, paddedMax)
    }
}
