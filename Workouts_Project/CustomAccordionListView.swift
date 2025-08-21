//
//  CustomAccordionListView.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 25/05/25.
//

import SwiftUI

// MARK: - Data Models
struct CustomListItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let accordionItems: [CustomAccordionSubItem]
    
    static func generateSampleData() -> [CustomListItem] {
        return (1...100).map { index in
            CustomListItem(
                title: "Custom Item \(index)",
                subtitle: "Custom description for item \(index)",
                accordionItems: (1...5).map { subIndex in
                    CustomAccordionSubItem(
                        title: "Custom Sub-item \(subIndex)",
                        detail: "Custom detail for sub-item \(subIndex) of item \(index)",
                        icon: ["star.fill", "heart.fill", "bolt.fill", "leaf.fill", "flame.fill"][subIndex - 1]
                    )
                }
            )
        }
    }
}

struct CustomAccordionSubItem: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let icon: String
}

// MARK: - Custom List Container
struct CustomListContainer: View {
    let items: [CustomListItem]
    let onDelete: (IndexSet) -> Void
    let expandedItems: Set<UUID>
    let onToggle: (UUID) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    CustomAccordionRow(
                        item: item,
                        isExpanded: expandedItems.contains(item.id),
                        onToggle: { onToggle(item.id) },
                        onDelete: { onDelete(IndexSet(integer: index)) }
                    )
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                }
            }
            .padding(.vertical, 8)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
}

// MARK: - Custom Accordion Row
struct CustomAccordionRow: View {
    let item: CustomListItem
    let isExpanded: Bool
    let onToggle: () -> Void
    let onDelete: () -> Void
    
    @State private var dragOffset: CGSize = .zero
    @State private var isDeleting = false
    
    private let deleteThreshold: CGFloat = -100
    
    var body: some View {
        VStack(spacing: 0) {
            // Main row content
            HStack {
                // Leading content
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(item.subtitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Trailing chevron
                Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle")
                    .font(.system(size: 24))
                    .foregroundColor(isExpanded ? .blue : .gray)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isExpanded)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(UIColor.systemBackground))
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    onToggle()
                }
            }
            
            // Custom Accordion Content
            if isExpanded {
                CustomAccordionContent(items: item.accordionItems)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)).combined(with: .scale(scale: 0.95)),
                        removal: .opacity.combined(with: .move(edge: .top)).combined(with: .scale(scale: 0.95))
                    ))
            }
        }
        .background(Color(UIColor.systemBackground))
        .offset(dragOffset)
        .scaleEffect(isDeleting ? 0.9 : 1.0)
        .opacity(isDeleting ? 0.6 : 1.0)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.width < 0 {
                        dragOffset = CGSize(width: max(value.translation.width, deleteThreshold * 1.5), height: 0)
                    }
                }
                .onEnded { value in
                    if value.translation.width < deleteThreshold {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isDeleting = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onDelete()
                        }
                    } else {
                        withAnimation(.spring()) {
                            dragOffset = .zero
                        }
                    }
                }
        )
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isExpanded)
        .animation(.spring(), value: dragOffset)
        .animation(.easeInOut(duration: 0.3), value: isDeleting)
    }
}

// MARK: - Custom Accordion Content
struct CustomAccordionContent: View {
    let items: [CustomAccordionSubItem]
    
    var body: some View {
        VStack(spacing: 0) {
            // Separator line
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 1)
                .padding(.horizontal, 20)
            
            // Sub-items
            ForEach(Array(items.enumerated()), id: \.element.id) { index, subItem in
                CustomSubItemRow(subItem: subItem)
                
                if index < items.count - 1 {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 0.5)
                        .padding(.leading, 60)
                }
            }
        }
        .background(Color(UIColor.secondarySystemGroupedBackground))
    }
}

// MARK: - Custom Sub-Item Row
struct CustomSubItemRow: View {
    let subItem: CustomAccordionSubItem
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: subItem.icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(subItem.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(subItem.detail)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Trailing indicator
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onTapGesture {
            // Handle sub-item tap if needed
            print("Tapped: \(subItem.title)")
        }
        .onLongPressGesture(minimumDuration: 0) {
            // Empty - just for press effect
        } onPressingChanged: { pressing in
            isPressed = pressing
        }
    }
}

// MARK: - Main Custom Accordion List View
struct CustomAccordionListView: View {
    @State private var items = CustomListItem.generateSampleData()
    @State private var expandedItems: Set<UUID> = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Custom Accordion")
                            .font(.system(size: 28, weight: .bold))
                        
                        Text("\(items.count) items")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring()) {
                            if expandedItems.count == items.count {
                                expandedItems.removeAll()
                            } else {
                                expandedItems = Set(items.map(\.id))
                            }
                        }
                    }) {
                        Image(systemName: expandedItems.count == items.count ? "minus.circle.fill" : "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(UIColor.systemGroupedBackground))
                
                // Custom List Container
                CustomListContainer(
                    items: items,
                    onDelete: deleteItems,
                    expandedItems: expandedItems,
                    onToggle: toggleItem
                )
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
    }
    
    private func deleteItems(at offsets: IndexSet) {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            for index in offsets {
                let itemId = items[index].id
                expandedItems.remove(itemId)
            }
            items.remove(atOffsets: offsets)
        }
    }
    
    private func toggleItem(_ itemId: UUID) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            if expandedItems.contains(itemId) {
                expandedItems.remove(itemId)
            } else {
                expandedItems.insert(itemId)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    CustomAccordionListView()
}
