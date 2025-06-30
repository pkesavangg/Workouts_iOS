//
//  ScrollViewTextField.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 11/06/25.
//

import SwiftUI


struct ScrollViewTextField: View {
    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 30) {
                Text("What's your name?")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .padding(.top, 16)
                
                Text("We just need a first name or even a nickname. But rest assured we protect whatever info you give us.")
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding(.top, 16)
                TextField("Enter text here", text: .constant(""))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.top, 30)
                TextField("Enter text here", text: .constant(""))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.top, 30)
            }
            //.padding(.top, 70)
        }
    }
}

struct ScrollTextFieldTestingView: View {
    @State var selectedIndex: Int = 0
    private var stepViews: [AnyView] {
        [AnyView(ScrollViewTextField()), AnyView(Text("Step 2")), AnyView(Text("Step 3"))]
    }
    var body: some View {
        VStack {
            PageHeaderView(
                leadingButtonView: AnyView(
                    Button(action: {
                        
                    }) {
                        Image(systemName: "chevron.left")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 22, height: 22)
                            
                    }
                ),
                trailingButtonView: AnyView(
                    Image(systemName: "chevron.left")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 22, height: 22)
                ),
                onLeadingButtonTap: nil,
                onTrailingButtonTap: nil
            )
            .padding(.horizontal, 16)
            
            AppProgressView()
                .padding(.top, 16)
            SwiperView(
                selectedIndex: $selectedIndex,
                views: stepViews
            )
            
            footerButtons
        }
    }
    
    private var footerButtons: some View {
        // TODO: Need to replace with the button component from the common components
        HStack {
            Button("back") {
                withAnimation {
                    if selectedIndex > 0 {
                        selectedIndex -= 1
                    }
                }
            }
            .foregroundColor(.blue)
            
            Spacer()
            
            Button("Next") {
                withAnimation {
                    if selectedIndex < stepViews.count - 1 {
                        selectedIndex += 1
                    }
                }
            }
            .foregroundColor(.blue)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
    }
}

#Preview {
    ScrollTextFieldTestingView()
}

struct SwiperView<Content: View>: View {
    @Binding var selectedIndex: Int
    let views: [Content]
    
    init(
        selectedIndex: Binding<Int>,
        views: [Content],
    ) {
        self._selectedIndex = selectedIndex
        self.views = views
    }

    @GestureState private var dragOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                ForEach(0..<views.count, id: \.self) { i in
                    views[i]
                        .padding(.horizontal)
                        .frame(width: geometry.size.width) // no .padding here
                }
            }
            .frame(width: geometry.size.width * CGFloat(views.count), alignment: .leading)
            .offset(x: -CGFloat(selectedIndex) * geometry.size.width + dragOffset)
            .animation(.easeInOut(duration: 0.3), value: selectedIndex)
        }
    }
}


import SwiftUI

struct PageHeaderView: View {
    let leadingButtonView: AnyView
    var trailingButtonView: AnyView?
    let onLeadingButtonTap: (() -> Void)?
    let onTrailingButtonTap: (() -> Void)?
    let title: String? = nil
    
    var body: some View {
        HStack {
            leadingButtonView
            Spacer()
            if let title = title {
                Text(title)
                    .font(.headline)
                    .padding(.trailing, trailingButtonView != nil ? 0 : 24)
            }
            Spacer()
            
            if let view = trailingButtonView {
                view
            }
        }
    }
}

struct AppProgressView: View {
    
    let progressValue: Double = 0.5
    var body: some View {
        VStack {
            ProgressView(value: 0.5)
                .animation(.easeInOut, value: progressValue)
        }
    }
}
