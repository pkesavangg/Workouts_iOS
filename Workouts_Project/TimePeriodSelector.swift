//
//  TimePeriodSelector.swift
//  Workouts_Project
//
//  Created by Assistant on 04/07/25.
//

import SwiftUI

struct TimePeriodSelector: View {
    @Binding var selectedPeriod: TimePeriod
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Button(action: {
                    selectedPeriod = period
                }) {
                    Text(period.displayName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(selectedPeriod == period ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            selectedPeriod == period 
                                ? Color.blue
                                : Color.clear
                        )
                }
            }
        }
        .background(Color(.systemGray5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .animation(.easeInOut(duration: 0.2), value: selectedPeriod)
    }
}

#Preview {
    TimePeriodSelector(selectedPeriod: .constant(.week))
        .padding()
}
