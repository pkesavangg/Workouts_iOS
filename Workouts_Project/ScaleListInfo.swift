//
//  ScaleListInfo.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 21/06/25.
//

import SwiftUI

struct ScaleItemInfo: Identifiable {
    let id = UUID()
    let productName: String
    let sku: String
    let imgPath: String?  // Optional
    let setupType: String
    let bodyComp: Bool
}

let SCALES: [ScaleItemInfo] = [
    ScaleItemInfo(productName: "AppSync Body Fat Scale", sku: "0341", imgPath: nil, setupType: "appSync", bodyComp: true),
    ScaleItemInfo(productName: "AppSync Bathroom Scale", sku: "0342", imgPath: nil, setupType: "appSync", bodyComp: false),
    ScaleItemInfo(productName: "AppSync Body Fat Scale", sku: "0343", imgPath: nil, setupType: "appSync", bodyComp: true),
    ScaleItemInfo(productName: "AppSync Body Fat Scale", sku: "0345", imgPath: nil, setupType: "appSync", bodyComp: true),
    ScaleItemInfo(productName: "AppSync Body Fat Scale", sku: "0346", imgPath: nil, setupType: "appSync", bodyComp: true),
    ScaleItemInfo(productName: "AppSync Body Fat Scale", sku: "0347", imgPath: nil, setupType: "appSync", bodyComp: true),
    ScaleItemInfo(productName: "Basic AppSync Bathroom Scale", sku: "0358", imgPath: nil, setupType: "appSync", bodyComp: false),
    ScaleItemInfo(productName: "Basic AppSync Bathroom Scale", sku: "0359", imgPath: nil, setupType: "appSync", bodyComp: false),
    ScaleItemInfo(productName: "AppSync Bathroom Scale", sku: "0364", imgPath: nil, setupType: "appSync", bodyComp: true),
    ScaleItemInfo(productName: "AppSync Body Fat Scale", sku: "0369", imgPath: nil, setupType: "appSync", bodyComp: true),
    ScaleItemInfo(productName: "AppSync Body Fat Scale", sku: "0370", imgPath: nil, setupType: "appSync", bodyComp: true),
    ScaleItemInfo(productName: "AppSync Bathroom Scale", sku: "0371", imgPath: nil, setupType: "appSync", bodyComp: false),
    ScaleItemInfo(productName: "Bluetooth Smart Scale", sku: "0375", imgPath: nil, setupType: "bluetooth", bodyComp: false),
    ScaleItemInfo(productName: "Bluetooth Smart Scale", sku: "0376", imgPath: nil, setupType: "bluetooth", bodyComp: false),
    ScaleItemInfo(productName: "Bluetooth Smart Scale", sku: "0378", imgPath: nil, setupType: "lcbt", bodyComp: true),
    ScaleItemInfo(productName: "Bluetooth Smart Scale", sku: "0380", imgPath: nil, setupType: "bluetooth", bodyComp: false),
    ScaleItemInfo(productName: "Bluetooth Smart Scale", sku: "0382", imgPath: nil, setupType: "bluetooth", bodyComp: true),
    ScaleItemInfo(productName: "Bluetooth Scale", sku: "0383", imgPath: nil, setupType: "lcbt", bodyComp: true),
    ScaleItemInfo(productName: "Wi-Fi Smart Scale", sku: "0384", imgPath: nil, setupType: "espTouchWifi", bodyComp: true),
    ScaleItemInfo(productName: "Wi-Fi Smart Scale", sku: "0385", imgPath: nil, setupType: "wifi", bodyComp: true),
    ScaleItemInfo(productName: "Wi-Fi Smart Scale", sku: "0396", imgPath: nil, setupType: "wifi", bodyComp: false),
    ScaleItemInfo(productName: "Wi-Fi Smart Scale", sku: "0397", imgPath: nil, setupType: "espTouchWifi", bodyComp: false),
    ScaleItemInfo(productName: "AccuCheck Verve Smart Scale", sku: "0412", imgPath: nil, setupType: "btWifiR4", bodyComp: true)
]
func filteredScales(for segment: ScaleSegment) -> [ScaleItemInfo] {
    switch segment {
    case .all:
        return SCALES
    case .bluetooth:
        return SCALES.filter { ["bluetooth", "lcbt", "btWifiR4"].contains($0.setupType) }
    case .wifi:
        return SCALES.filter { ["wifi", "espTouchWifi", "btWifiR4"].contains($0.setupType) }
    case .appsync:
        return SCALES.filter { $0.setupType == "appSync" }
    }
}

enum ScaleSegment: String, CaseIterable, Identifiable {
    case all = "All"
    case bluetooth = "Bluetooth"
    case wifi = "WiFi"
    case appsync = "AppSync"

    var id: String { self.rawValue }
}


struct ScaleListView: View {
    let segment: ScaleSegment
    var body: some View {
        List(filteredScales(for: segment)) { scale in
            VStack(alignment: .leading) {
                Text(scale.sku)
                    .font(.headline)
                Text(scale.productName)
                    .font(.subheadline)
            }
        }
    }
}

struct ScaleMainView: View {
    @State private var selectedSegment: ScaleSegment = .all

    var body: some View {
        VStack {
            SegmentedButtonView(
                segments: ScaleSegment.allCases,
                selectedSegment: $selectedSegment
            )

            List(filteredScales(for: selectedSegment)) { scale in
                HStack(spacing: 16) {
                    // Left: Gray box as image placeholder
                    Rectangle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 48, height: 48)
                        .cornerRadius(8)

                    // Middle: SKU and product name
                    VStack(alignment: .leading, spacing: 4) {
                        Text(scale.sku)
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text(scale.productName.lowercased())
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Right: SF Symbol icon
                    Image(systemName: "viewfinder")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
                .padding(.vertical, 8)
                .listRowBackground(Color.black) // match dark theme
            }

        }
    }

}


//
//  SegmentedPickerView.swift
//  meApp
//
//  Created by Lakshmi Priya on 09/06/25.
//
import SwiftUI

struct SegmentedButtonView<T: CaseIterable & RawRepresentable & Identifiable & Hashable>: View where T.RawValue == String {
    let segments: [T]
    @Binding var selectedSegment: T
    /// Stores the width of each segment (indexed by its position in the `segments` array).
    @State private var segmentWidths: [Int: CGFloat] = [:]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(segments.enumerated()), id: \.element) { index, segment in
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)) {
                        selectedSegment = segment
                    }
                }) {
                    Text(segment.rawValue.uppercased())
                        .fontWeight(.bold)
                        .foregroundColor(selectedSegment == segment ? .secondary : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            GeometryReader { geometry in
                                Color.clear
                                    .onAppear {
                                        segmentWidths[index] = geometry.size.width
                                    }
                                    .onChange(of: geometry.size.width) {
                                        segmentWidths[index] = geometry.size.width
                                    }
                            }
                        )
                }
                .zIndex(1)
                .id(segment)
            }
        }
        .background(
            // Animated background
            RoundedRectangle(cornerRadius: 16)
                .fill(.black)
                .frame(width: selectedWidth())
                .offset(x: calculateOffset())
                .animation(
                    .spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0),
                    value: selectedSegment
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    /// Calculates the x-offset required to place the highlight behind the selected segment.
    private func calculateOffset() -> CGFloat {
        guard
            let selectedIndex = segments.firstIndex(where: { $0.id == selectedSegment.id }),
            !segmentWidths.isEmpty
        else { return 0 }

        let totalWidth = segmentWidths.values.reduce(0, +)
        let precedingWidth = (0..<selectedIndex).reduce(CGFloat(0)) { $0 + (segmentWidths[$1] ?? 0) }
        let selectedWidth = segmentWidths[selectedIndex] ?? 0

        // Start from the leading edge (-totalWidth/2), then move past the widths before the selected
        // segment and finally centre the highlight under the selected segment.
        return -totalWidth / 2 + precedingWidth + (selectedWidth / 2)
    }

    /// Returns the width of the currently selected segment (or zero until measured).
    private func selectedWidth() -> CGFloat {
        guard let index = segments.firstIndex(where: { $0.id == selectedSegment.id }) else { return 0 }
        return segmentWidths[index] ?? 0
    }
}

#Preview {
    ScaleMainView()
}
