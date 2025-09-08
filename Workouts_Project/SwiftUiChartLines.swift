//
//  SwiftUiChartLines.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 01/09/25.
//

import SwiftUI

//struct SwiftUiChartLines: View {
//    var body: some View {
//        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
//    }
//}

#Preview {
    SwiftUiChartLines()
}

import SwiftUI
import Charts


struct SwiftUiChartLines: View {
    let data: [Int] = [10, 20, 15, 25, 18]

    var body: some View {
        Chart {
            ForEach(data.indices, id: \.self) { index in
                LineMark(
                    x: .value("Index", index),
                    y: .value("Value", data[index])
                )
                .interpolationMethod(.catmullRom) // smooth curve
                .foregroundStyle(.blue)
                
                PointMark(
                    x: .value("Index", index),
                    y: .value("Value", data[index])
                )
                .foregroundStyle(.red)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: 1)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: []))
                    .foregroundStyle(.blue)   // vertical grid line
                AxisTick(stroke: StrokeStyle(lineWidth: 1, dash: []))                   // short tick at the axis baseline
                AxisValueLabel()             // label (0, 1, 2…)
            }
        }
        .chartYAxis {
            AxisMarks {
                AxisGridLine()
                    .foregroundStyle(.gray)
                AxisTick()
                AxisValueLabel()
            }
        }
        .frame(height: 300)
        .padding()
    }
}


