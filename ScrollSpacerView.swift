//
//  ScrollSpacerView.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 10/07/25.
//

import SwiftUI

/// A utility view that helps ensure proper spacing in ScrollViews
/// This is particularly useful for weight chart views to maintain proper padding at bottom
struct ScrollSpacerView: View {
    /// The minimum amount of space to add at the bottom
    var minHeight: CGFloat = 80
    
    /// Additional spacing beyond the minimum
    var additionalSpacing: CGFloat = 0
    
    /// Whether to show a visual indicator for debugging
    var showDebugColor: Bool = false
    
    var body: some View {
        Rectangle()
            .foregroundColor(showDebugColor ? .red.opacity(0.15) : .clear)
            .frame(height: minHeight + additionalSpacing)
    }
}

/// A view that demonstrates how to use the ScrollSpacerView
struct ScrollSpacerDemoView: View {
    @State private var showSheet = false
    
    var body: some View {
        VStack {
            Button("Show Chart Sheet") { 
                showSheet = true 
            }
            .buttonStyle(.borderedProminent)
            
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(0..<5) { i in
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.1))
                            .frame(height: 60)
                            .overlay(
                                Text("Content \(i)")
                                    .foregroundColor(.blue)
                            )
                    }
                    
                    // Add the spacer view at the bottom
                    ScrollSpacerView(minHeight: 100, showDebugColor: true)
                }
                .padding()
            }
        }
        .sheet(isPresented: $showSheet) {
            WeightChartSheetView()
                .presentationDetents([.height(500)])
                .presentationDragIndicator(.visible)
        }
    }
}

/// Example sheet view that shows how to use ScrollSpacerView with a chart
struct WeightChartSheetView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Weight Chart")
                .font(.headline)
            
            ScrollView {
                VStack(spacing: 16) {
                    // Chart or other content would go here
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.1))
                        .frame(height: 250)
                        .overlay(
                            Text("Chart Placeholder")
                                .foregroundColor(.blue)
                        )
                    
                    // Information below the chart
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(0..<3) { i in
                            HStack {
                                Text("Stat \(i):")
                                    .fontWeight(.medium)
                                Spacer()
                                Text("Value \(i)")
                                    .foregroundColor(.secondary)
                            }
                            Divider()
                        }
                    }
                    
                    // Add spacer at the bottom for better scrolling
                    ScrollSpacerView(minHeight: 50)
                }
                .padding()
            }
        }
    }
}

#Preview {
    ScrollSpacerDemoView()
}

