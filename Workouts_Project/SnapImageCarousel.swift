//
//  SnapImageCarousel.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 02/09/25.
//


import SwiftUI

struct SnapImageCarousel: View {
    let imageNames: [String]
    @Environment(\.horizontalSizeClass) private var hSize

    // We render N copies in a "virtual" ring and start in the middle.
    private let ringCopies = 10

    // The scrollPosition needs a stable Int ID
    @State private var currentID: Int? = 0

    var body: some View {
        GeometryReader { proxy in
            // Layout constants
            let isPad = (hSize == .regular)
            let centerSize = isPad ? CGSize(width: 500, height: 350)
                                   : CGSize(width: 300, height: 225)
            let sideScale: CGFloat = isPad ? (275.0 / 350.0) : (200.0 / 250.0)
            let spacing: CGFloat = isPad ? 24 : 1
            let sidePadding = (proxy.size.width - centerSize.width) / 2

            // Guard: nothing to render
            let count = max(imageNames.count, 1)
            let ringCount = count * ringCopies
            let ringStart = ringCount / 2        // a safe middle
            let visibleIndex = (currentID! % count + count) % count

            VStack(spacing: 8) {
                ScrollView(.horizontal) {
                    LazyHStack(spacing: spacing) {
                        // Virtual slides
                        ForEach(0..<ringCount, id: \.self) { i in
                            let realIndex = i % count
                            if let url = URL(string: imageNames[realIndex]) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let img):
                                        img
                                            .resizable()
                                            .scaledToFill()
                                    case .failure(_):
                                        Color.secondary.opacity(0.1)
                                            .overlay(
                                                Image(systemName: "photo")
                                                    .font(.largeTitle)
                                                    .opacity(0.3)
                                            )
                                    case .empty:
                                        ProgressView()
                                    @unknown default:
                                        Color.clear
                                    }
                                }
                                .frame(width: centerSize.width, height: centerSize.height)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .shadow(radius: 8)
                                .scrollTransition(axis: .horizontal) { content, phase in
                                    content
                                        .scaleEffect(phase.isIdentity ? 1.0 : sideScale)
                                        .opacity(phase.isIdentity ? 1.0 : 0.9)
                                }
                                .id(i) // important: the virtual (ring) id
                            }
                        }
                    }
                    .scrollTargetLayout()
                    .padding(.horizontal, sidePadding)
                    .frame(height: centerSize.height + 16)
                }
                .scrollIndicators(.hidden)
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $currentID)
                .onAppear {
                    // Start centered in the ring
                    currentID = ringStart
                }
                .onChange(of: currentID!) { _, newID in
                    // If we drift near either ring edge, jump back to the middle equivalent.
                    let threshold = count * 2 // how close to the edge before snapping back
                    if newID < threshold || newID > ringCount - threshold {
                        let middleEquivalent = ringStart + (newID % count)
                        var t = Transaction()
                        t.disablesAnimations = true
                        withTransaction(t) {
                            currentID = middleEquivalent
                        }
                    }
                }

                // Dots (reflect the "real" index)
                HStack(spacing: 8) {
                    ForEach(0..<count, id: \.self) { i in
                        let isSelected = (i == visibleIndex)
                        Circle()
                            .frame(width: isSelected ? 7 : 5, height: isSelected ? 7 : 5)
                            .opacity(isSelected ? 1.0 : 0.5)
                            .animation(.easeInOut(duration: 0.2), value: visibleIndex)
                            .onTapGesture {
                                // Jump to the chosen slide near current center
                                let target = (ringStart + i)
                                withAnimation(.snappy) { currentID = target }
                            }
                            .accessibilityLabel("Slide \(i + 1)")
                            .accessibilityAddTraits(isSelected ? .isSelected : [])
                    }
                }
                .padding(.bottom, 4)
            }
        }
    }
}


struct SnapImageCarouselContentView: View {
    var body: some View {
        ScrollView {
            Text("SnapImageCarouselContentView")
                .font(.headline)
            
            Text("SnapImageCarouselContentView")
                .font(.headline)
            
            
            Text("SnapImageCarouselContentView")
                .font(.headline)
            
            
            Text("SnapImageCarouselContentView")
                .font(.headline)
            VStack(spacing: 8) {
                SnapImageCarousel(imageNames: [
                    "https://s3.amazonaws.com/gg-mark/wms/image/6rWSd7o0agFUzr3ZIqiXwJP.jpg",
                    "https://s3.amazonaws.com/gg-mark/wms/image/6rWSd7o0agFUzr3ZIqiXJP.jpg", "https://s3.amazonaws.com/gg-mark/wms/image/6rWSd7o0agFUzr3ZIqiXJP.jpg"])
                    .background(Color(.systemBackground))
            }
           
        }

    }
}

#Preview {
    SnapImageCarouselContentView()
}

#Preview {
    SnapImageCarouselContentView()
}


import SwiftUI

import SwiftUI

struct PromoCodeView: View {
    let code: String = "5ZHTL9M8"
    
    var body: some View {
        VStack {
            Text(formatExpirationDate("2025-09-02T00:00:00.000Z"))
        }
        HStack(spacing: 0) {
            // Left side: Code with dashed border
            Text(formatExpirationDate("2025-10-01T00:00:00.000Z"))
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.black)
                .frame(width: 209, height: 47)
                .background(
                    // Background fill
                    UnevenRoundedRectangle(
                        cornerRadii: .init(
                            topLeading: 8,
                            bottomLeading: 8,
                            bottomTrailing: 0, topTrailing: 0
                        )
                    )
                    .fill(Color(red: 0.95, green: 0.88, blue: 0.88))
                )
                .overlay(
                    // Dashed border
                    UnevenRoundedRectangle(
                        cornerRadii: .init(
                            topLeading: 8,
                            bottomLeading: 8,
                            bottomTrailing: 0, topTrailing: 0
                        )
                    )
                    .strokeBorder(
                        Color(red: 0.78, green: 0.39, blue: 0.33),
                        style: StrokeStyle(lineWidth: 2, dash: [4])
                    )
                )
            
            // Right side: Copy button
            Button(action: {
                UIPasteboard.general.string = code
            }) {
                Text("COPY")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 100, height: 47)
                    .background(
                        UnevenRoundedRectangle(
                            cornerRadii: .init(
                                topLeading: 0,
                                bottomLeading: 0,
                                bottomTrailing: 8, topTrailing: 8
                            )
                        )
                        .fill(Color(red: 0.78, green: 0.39, blue: 0.33))
                    )
            }
            .offset(x: -2)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding()
    }
}

#Preview {
    HStack(alignment: .center, spacing: 10) {Text("169").font(.body).fontWeight(.bold) }
    .padding(.horizontal, 4)
    .padding(.top, 9)
    .padding(.bottom, 10)
    .frame(width: 35, height: 20, alignment: .center)
    .background(.red)
    .cornerRadius(999)
}


#Preview {
    PromoCodeView()
}


func formatExpirationDate(_ expiresAtString: String?) -> String {
    guard let s = expiresAtString else { return "" }

    // Parse ISO8601 with/without fractional seconds
    let iso1 = ISO8601DateFormatter()
    iso1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    let iso2 = ISO8601DateFormatter()
    iso2.formatOptions = [.withInternetDateTime]

    guard let expiresAt = iso1.date(from: s) ?? iso2.date(from: s) else { return "" }

    let cal = Calendar.current
    let todayStart   = cal.startOfDay(for: Date())
    let expiryStart  = cal.startOfDay(for: expiresAt)

    // Difference in calendar days (not hours)
    let daysLeft = cal.dateComponents([.day], from: todayStart, to: expiryStart).day ?? 0

    if daysLeft > 7 {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "M/d/yyyy" // no leading zeros
        return "Offer valid through \(formatter.string(from: expiresAt))"
    } else if daysLeft > 1 {
        return "Offer expires in \(daysLeft) days"
    } else if daysLeft == 1 {
        return "Offer expires in 1 day"
    } else if daysLeft == 0 {
        return "Offer expires today"
    } else {
        return "" // already expired
    }
}
