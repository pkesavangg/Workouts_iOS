//
//  SnapImageCarousel.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 02/09/25.
//


import SwiftUI

import SwiftUI

struct SnapImageCarousel: View {
    let imageNames: [String]
    @Environment(\.horizontalSizeClass) private var hSize
    @State private var currentID: Int? = 0   // track the centered slide

    var body: some View {
        GeometryReader { proxy in
            // Local constants (Sendable) so the transition closure can capture them
            let isPad = (hSize == .regular)
            let centerSize = isPad ? CGSize(width: 500, height: 350)
                                   : CGSize(width: 300, height: 225)
            let sideScale: CGFloat = isPad ? (275.0 / 350.0) : (200.0 / 250.0)
            let spacing: CGFloat = isPad ? 24 : 1
            let sidePadding = (proxy.size.width - centerSize.width) / 2

            VStack(spacing: 8) {
                ScrollView(.horizontal) {
                    HStack(spacing: spacing) {
                        ForEach(imageNames.indices, id: \.self) { i in
                            if let url = URL(string: imageNames[i]) {
                                AsyncImage(url: url)
                                    .frame(width: centerSize.width, height: centerSize.height)
                                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                    .shadow(radius: 8)
                                    .scrollTransition(axis: .horizontal) { content, phase in
                                        content
                                            .scaleEffect(phase.isIdentity ? 1.0 : sideScale)
                                            .opacity(phase.isIdentity ? 1.0 : 0.9)
                                    }
                                    .id(i) // important: matches the scrollPosition id
                            }

                        }
                    }
                    .scrollTargetLayout()
                    .padding(.horizontal, sidePadding)
                    .frame(height: centerSize.height + 16)
                }
                .scrollIndicators(.hidden)
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $currentID) // bind current item
                .onAppear { currentID = 0 }

                // Dot indicator
                HStack(spacing: 8) {
                    ForEach(imageNames.indices, id: \.self) { i in
                        let isSelected = (i == (currentID ?? 0))
                        Circle()
                            .frame(width: isSelected ? 7 : 5, height: isSelected ? 7 : 5)
                            .opacity(isSelected ? 1.0 : 0.5)
                            .animation(.easeInOut(duration: 0.2), value: currentID)
                            .onTapGesture {
                                withAnimation(.snappy) { currentID = i } // taps jump to slide
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
                SnapImageCarousel(imageNames: ["https://s3.amazonaws.com/gg-mark/wms/image/6rWSd7o0agFUzr3ZIqiXJP.jpg", "https://s3.amazonaws.com/gg-mark/wms/image/6rWSd7o0agFUzr3ZIqiXJP.jpg"])
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
