//
//  AccordionListView.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 25/05/25.
//

import SwiftUI

// MARK: - Data Models
struct ListItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let accordionItems: [AccordionSubItem]
    
    static func generateSampleData() -> [ListItem] {
        return (1...100).map { index in
            ListItem(
                title: "Item \(index)",
                subtitle: "Description for item \(index)",
                accordionItems: (1...5).map { subIndex in
                    AccordionSubItem(
                        title: "Sub-item \(subIndex)",
                        detail: "Detail for sub-item \(subIndex) of item \(index)"
                    )
                }
            )
        }
    }
}

struct AccordionSubItem: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
}

// MARK: - Main List View
struct AccordionListView: View {
    @State private var items = ListItem.generateSampleData()
    @State private var expandedItems: Set<UUID> = []
    
    var body: some View {
        NavigationView {
            List {
                ForEach(items) { item in
                    AccordionRowView(
                        item: item,
                        isExpanded: expandedItems.contains(item.id),
                        onToggle: {
                            if expandedItems.contains(item.id) {
                                expandedItems.remove(item.id)
                            } else {
                                expandedItems.insert(item.id)
                            }
                        }
                    )
                }
                .onDelete(perform: deleteItems)
            }
            .navigationTitle("Accordion List")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private func deleteItems(at offsets: IndexSet) {
        withAnimation(.easeInOut(duration: 0.3)) {
            for index in offsets {
                let itemId = items[index].id
                expandedItems.remove(itemId)
            }
            items.remove(atOffsets: offsets)
        }
    }
}

// MARK: - Accordion Row View
struct AccordionRowView: View {
    let item: ListItem
    let isExpanded: Bool
    let onToggle: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Main row content
            Button(action: onToggle) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(item.subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 0 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            // Accordion content
            if isExpanded {
                VStack(spacing: 0) {
                    Divider()
                        .padding(.vertical, 8)
                    
                    ForEach(item.accordionItems) { subItem in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(subItem.title)
                                    .font(.body)
                                    .fontWeight(.medium)
                                
                                Text(subItem.detail)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                        .padding(.vertical, 6)
                        .padding(.leading, 16)
                        
                        if subItem.id != item.accordionItems.last?.id {
                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .slide),
                    removal: .opacity.combined(with: .slide)
                ))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isExpanded)
    }
}

// MARK: - Preview
#Preview {
    AccordionListView()
}

