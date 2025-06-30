//
//  Draggle_items.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 26/05/25.
//

import SwiftUI

//struct Draggle_items: View {
//    var body: some View {
//        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
//    }
//}

#Preview {
//    ZStack {
//        Color.red
//        testView()
//
//    }
    ContentView2()
}

import SwiftUI

import SwiftUI

import SwiftUI

struct ContentView2: View {
    @State var arrColors: [Color] = [
        .purple, .black, .indigo, .cyan, .brown, .yellow, .mint,
        .orange, .red, .green, .gray, .teal, .yellow.opacity(0.5)
    ]
    @State var draggingColor: Color?

    var body: some View {
        VStack {
            Text("SwiftUI Movable Grid")
                .bold()
                .font(.title)
                .padding(.bottom, 20)

            ScrollView(.vertical) {
                VStack(spacing: 10) {
                    ForEach(chunks(of: arrColors, size: 3), id: \.self) { row in
                        HStack(spacing: 10) {
                            ForEach(row, id: \.self) { color in
                                GeometryReader { geo in
                                    let size = geo.size

                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(color.gradient)
                                        .draggable(color) {
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(color.gradient.opacity(0.7))
                                                .frame(width: size.width, height: size.height)
                                                .background(Color.clear)
                                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                                .onAppear {
                                                    draggingColor = color
                                                }
                                        }
                                        .dropDestination(for: Color.self) { item, location in
                                            print("Drop destination at \(item)")
                                            return false
                                        } isTargeted: { status in
                                            if let draggingColor = draggingColor, draggingColor != color {
                                                if let sourceIndex = arrColors.firstIndex(of: draggingColor),
                                                   let destinationIndex = arrColors.firstIndex(of: color) {
                                                    withAnimation {
                                                        let movedItem = arrColors.remove(at: sourceIndex)
                                                        arrColors.insert(movedItem, at: destinationIndex)
                                                    }
                                                }
                                            }
                                        }
                                }
                                .frame(height: 100)
                            }
                        }
                    }
                }
            }
        }
        .padding()
    }

    /// Helper to chunk the array into grid rows
    func chunks<T>(of array: [T], size: Int) -> [[T]] {
        stride(from: 0, to: array.count, by: size).map {
            Array(array[$0..<min($0 + size, array.count)])
        }
    }
}


// MARK: - Preview Provider
//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}



//
// ContentView.swift
// DummyProject
//
// Created by Lakshmi Priya on 26/05/25.
//
import SwiftUI
struct Draggle_items: View {
  @State private var items = Array(1...12).map { "Item \($0)" }
  @State private var draggingItem: String?
  // 3 columns = 4 rows for 12 items
  let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 3)
  var body: some View {
    LazyVGrid(columns: columns, spacing: 16) {
      ForEach(items, id: \.self) { item in
          VStack {
              ZStack {
                  RoundedRectangle(cornerRadius: 16)
                      .fill(draggingItem == item ? Color.green.opacity(0.5) : Color.blue.opacity(0.2))
                      .overlay(
                          RoundedRectangle(cornerRadius: 16)
                              .stroke(draggingItem == item ? Color.green : Color.blue, lineWidth: 2)
                      )
//                  Text(item)
//                      .foregroundColor(.blue)
              }
              .frame(height: 60)
              .contentShape(RoundedRectangle(cornerRadius: 16)) // ensures hit testing matches shape
              .clipShape(RoundedRectangle(cornerRadius: 16))    // clips the drag image
              .background(Color.clear)                          // no extra background leakage
              .onDrag {
                  self.draggingItem = item
                  return NSItemProvider(object: item as NSString)
              }
              .onDrop(of: [.text], delegate: GridDropDelegate(
                  item: item,
                  items: $items,
                  draggingItem: $draggingItem
              ))
//              .animation(.default, value: items)

            .onDrag {
              self.draggingItem = item
              return NSItemProvider(object: item as NSString)
            } preview: {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.green)
                        .frame(width: 100, height: 60)
                    Text(item)
                        .foregroundColor(.white)
                }
                .frame(width: 100, height: 60)
                .background(Color.clear) // ensure no inherited background
                .mask(
                    RoundedRectangle(cornerRadius: 16)
                )
            }
            .onDrop(of: [.text], delegate: GridDropDelegate(
              item: item,
              items: $items,
              draggingItem: $draggingItem
            ))
            .animation(.default, value: items)
          }
          .background(Color.clear)
          .clipShape(RoundedRectangle(cornerRadius: 16))
      }
      .background(Color.clear)
      .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    .background(Color.yellow)
    .clipShape(RoundedRectangle(cornerRadius: 16))
  }
}
struct GridDropDelegate: DropDelegate {
  let item: String
  @Binding var items: [String]
  @Binding var draggingItem: String?
  func dropEntered(info: DropInfo) {
    guard let draggingItem = draggingItem,
       draggingItem != item,
       let fromIndex = items.firstIndex(of: draggingItem),
       let toIndex = items.firstIndex(of: item)
    else { return }
    // Move the item in the array
    withAnimation {
      items.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
    }
  }
  func performDrop(info: DropInfo) -> Bool {
    self.draggingItem = nil
    return true
  }
}


struct testView: View {
    var body: some View {
        ZStack {
          RoundedRectangle(cornerRadius: 16)
            .fill(true ? Color.green.opacity(0.5) : Color.blue.opacity(0.2))
            .frame(height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
              RoundedRectangle(cornerRadius: 16)
                .stroke(true ? Color.green : Color.blue, lineWidth: 2)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            )
          Text("item")
            .foregroundColor(.blue)
        }
    }
}



