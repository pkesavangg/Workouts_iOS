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
            viewModel.processEntries(entries)
        }
        .onChange(of: entries) { _, newEntries in
            viewModel.processEntries(newEntries)
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
    @ViewBuilder
    private var chartSection: some View {
        Chart {
            // Main weight line
            ForEach(viewModel.chartPoints) { point in
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
                .symbolSize(viewModel.selectedPoint?.id == point.id ? 100 : 50)
            }
            
            // Selection indicator
            if let selectedDate = viewModel.selectedDate {
                RuleMark(x: .value("Selected Date", selectedDate))
                    .foregroundStyle(.gray)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
            }
        }
        .chartYScale(domain: viewModel.weightRange.min...viewModel.weightRange.max)
        .chartScrollableAxes(.horizontal)
        .chartXVisibleDomain(length: viewModel.visibleDomainLength) // Dynamic visible domain based on data
        .chartScrollPosition(x: $viewModel.scrollPosition)
        .chartXSelection(value: Binding(
            get: { viewModel.selectedDate },
            set: { viewModel.selectPointAtDate($0) }
        ))
        .frame(height: 200)
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
