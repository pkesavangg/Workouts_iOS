//
//  WeightEntriesListView.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 04/07/25.
//

import SwiftUI

struct WeightEntriesListView: View {
    @StateObject private var viewModel = WeightEntriesViewModel()
    @State private var showChart = true
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    LoadingView()
                } else {
                    entriesContent
                }
            }
            .navigationTitle("Weight Entries")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(showChart ? "Hide Chart" : "Show Chart") {
                            withAnimation {
                                showChart.toggle()
                            }
                        }
                        
                        Button("Refresh") {
                            Task {
                                await viewModel.refreshData()
                            }
                        }
                        .disabled(viewModel.isLoading)
                    }
                }
                
                if viewModel.isLoggedIn {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Logout") {
                            viewModel.logout()
                        }
                    }
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
                Button("Retry") {
                    Task {
                        await viewModel.refreshData()
                    }
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .task {
                if !viewModel.isLoggedIn {
                    await viewModel.login()
                }
            }
        }
        
    }
    
    @ViewBuilder
    private var entriesContent: some View {
        if viewModel.entries.isEmpty {
            EmptyStateView()
        } else {
            VStack(spacing: 0) {
                if showChart {
                    WeightChartView(entries: viewModel.entries)
                        .padding(.vertical)
                        .background(Color(.systemBackground))
                        .transition(.opacity.combined(with: .move(edge: .top)))

                    Divider()
                }

                ScrollViewReader { proxy in
                    ZStack(alignment: .bottomTrailing) {
                        List {
                            ForEach(viewModel.entries) { entry in
                                WeightEntryRow(entry: entry)
                                    .id(entry.id) // stable id
                            }
                        }
                        // leave room so the last row isn’t hidden by the FABs
                        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 72) }
                        .refreshable { await viewModel.refreshData() }
//                        .onChange(of: viewModel.entries) { _, entries in
//                            // auto-jump to newest when data changes (top of list)
//                            if let first = entries.first {
//                                DispatchQueue.main.async {
//                                    withAnimation {
//                                        proxy.scrollTo(first.id, anchor: .top)
//                                    }
//                                }
//                            }
//                        }

                        // Floating buttons
                        VStack(spacing: 12) {
                            // scroll to TOP (latest)
                            Button {
                                if let first = viewModel.entries.first {
                                    withAnimation(.easeInOut) {
                                        proxy.scrollTo(first.id, anchor: .top)
                                    }
                                }
                            } label: {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 34))
                                    .padding(12)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                            .accessibilityLabel("Scroll to latest entry")

                            // scroll to BOTTOM (oldest)
                            Button {
                                if let last = viewModel.entries.last {
                                    withAnimation(.easeInOut) {
                                        proxy.scrollTo(last.id, anchor: .bottom)
                                    }
                                }
                            } label: {
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.system(size: 34))
                                    .padding(12)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                            .accessibilityLabel("Scroll to oldest entry")
                        }
                        .padding(.trailing, 16)
                        .padding(.bottom, 16)
                    }
                }

            }
        }
    }


}

// MARK: - Weight Entry Row
struct WeightEntryRow: View {
    let entry: WeightEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with weight and date
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.formattedWeight)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    if let source = entry.source {
                        Text(source.capitalized)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(sourceBackgroundColor)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(entry.formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let bmi = entry.bmi {
                        Text("BMI: \(String(format: "%.1f", bmi / 10.0))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Body composition metrics
            if hasBodyComposition {
                Divider()
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    if let bodyFat = entry.bodyFat {
                        MetricView(title: "Body Fat", value: "\(String(format: "%.1f", bodyFat / 10.0))%")
                    }
                    if let muscleMass = entry.muscleMass {
                        MetricView(title: "Muscle", value: "\(String(format: "%.1f", muscleMass / 10.0)) kg")
                    }
                    if let water = entry.water {
                        MetricView(title: "Water", value: "\(String(format: "%.1f", water / 10.0))%")
                    }
                    if let boneMass = entry.boneMass {
                        MetricView(title: "Bone", value: "\(String(format: "%.1f", boneMass / 10.0)) kg")
                    }
                    if let bmr = entry.bmr {
                        MetricView(title: "BMR", value: "\(Int(bmr)) cal")
                    }
                    if let metabolicAge = entry.metabolicAge {
                        MetricView(title: "Age", value: "\(Int(metabolicAge)) yrs")
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var hasBodyComposition: Bool {
        entry.bodyFat != nil || entry.muscleMass != nil || entry.water != nil || 
        entry.boneMass != nil || entry.bmr != nil || entry.metabolicAge != nil
    }
    
    private var sourceBackgroundColor: Color {
        guard let source = entry.source else {
            return .gray
        }
        switch source.lowercased() {
        case "manual":
            return .blue
        case "btwifir4":
            return .green
        default:
            return .gray
        }
    }
}

// MARK: - Metric View
struct MetricView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(6)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(6)
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading entries...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "scale.3d")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Weight Entries")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text("Pull to refresh or check your connection")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Preview
#Preview {
    WeightEntriesListView()
}
