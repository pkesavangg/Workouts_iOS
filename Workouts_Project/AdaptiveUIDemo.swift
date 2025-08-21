//
//  AdaptiveUIDemo.swift
//  Workouts_Project
//
//  Created for cross-platform UI demonstration
//

import SwiftUI

// MARK: - Sample Data Models
struct DemoItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let category: DemoCategory
    let isFavorite: Bool
    let dateCreated: Date
    
    static let samples = [
        DemoItem(title: "Workout Plan A", subtitle: "Full body strength training", category: .fitness, isFavorite: true, dateCreated: Date().addingTimeInterval(-86400 * 5)),
        DemoItem(title: "Cardio Session", subtitle: "30-minute HIIT workout", category: .fitness, isFavorite: false, dateCreated: Date().addingTimeInterval(-86400 * 3)),
        DemoItem(title: "Meal Prep Sunday", subtitle: "Weekly nutrition planning", category: .nutrition, isFavorite: true, dateCreated: Date().addingTimeInterval(-86400 * 2)),
        DemoItem(title: "Progress Photos", subtitle: "Monthly transformation check", category: .progress, isFavorite: false, dateCreated: Date().addingTimeInterval(-86400 * 1)),
        DemoItem(title: "Recovery Day", subtitle: "Stretching and mobility", category: .fitness, isFavorite: false, dateCreated: Date()),
        DemoItem(title: "Protein Smoothie", subtitle: "Post-workout nutrition", category: .nutrition, isFavorite: true, dateCreated: Date().addingTimeInterval(-86400 * 4)),
        DemoItem(title: "Body Measurements", subtitle: "Weekly tracking data", category: .progress, isFavorite: false, dateCreated: Date().addingTimeInterval(-86400 * 6)),
        DemoItem(title: "Yoga Session", subtitle: "Morning mindfulness practice", category: .fitness, isFavorite: true, dateCreated: Date().addingTimeInterval(-86400 * 7))
    ]
}

enum DemoCategory: String, CaseIterable, Identifiable {
    case fitness = "Fitness"
    case nutrition = "Nutrition" 
    case progress = "Progress"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .fitness: return "figure.strengthtraining.traditional"
        case .nutrition: return "fork.knife"
        case .progress: return "chart.line.uptrend.xyaxis"
        }
    }
    
    var color: Color {
        switch self {
        case .fitness: return .blue
        case .nutrition: return .green
        case .progress: return .orange
        }
    }
}

enum MacViewType: String, CaseIterable, Identifiable {
    case items = "Items"
    case categories = "Categories" 
    case settings = "Settings"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .items: return "list.bullet"
        case .categories: return "square.grid.2x2"
        case .settings: return "gearshape"
        }
    }
}

// MARK: - Main Adaptive Demo View
struct AdaptiveUIDemo: View {
    @State private var selectedTab = 0
    @State private var searchText = ""
    @State private var selectedCategory: DemoCategory? = nil
    @State private var showFavoritesOnly = false
    @State private var selectedItem: DemoItem? = nil
    @State private var selectedMacView: MacViewType = .items
    
    // Platform detection
    #if os(macOS)
    private let isMac = true
    #else
    private let isMac = false
    #endif
    
    @Environment(\.horizontalSizeClass) private var hSize
    #if os(iOS)
    @Environment(\.verticalSizeClass) private var vSize
    #endif

    // Treat macOS and any "regular" width (iPad, iPhone Plus in landscape) as split-friendly.
    private var isMacLike: Bool {
        #if os(macOS)
        return true
        #else
        return hSize == .regular
        #endif
    }
    
    var body: some View {
        Group {
            if isMacLike {
                macOSLayout
            } else {
                iOSLayout
            }
        }
        .onAppear {
            print("🖥️ Running on: \(isMac ? "macOS" : "iOS")")
        }
    }
    
    // MARK: - macOS Layout
    private var macOSLayout: some View {
        NavigationSplitView {
            // Sidebar for macOS with navigation
            macOSSidebarContent
                .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
        } detail: {
            // Detail view for macOS
            macOSDetailContent
                .navigationSplitViewColumnWidth(min: 400, ideal: 600)
        }
        .searchable(text: $searchText, placement: .sidebar, suggestions: {
            if !searchText.isEmpty {
                ForEach(filteredItems.prefix(3)) { item in
                    Text(item.title).searchCompletion(item.title)
                }
            }
        })
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                macOSToolbarContent
            }
        }
    }
    
    // MARK: - iOS Layout  
    private var iOSLayout: some View {
        TabView(selection: $selectedTab) {
            // List Tab
            NavigationStack {
                listContent
                    .navigationTitle("Demo Items")
                    .searchable(text: $searchText)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            iOSToolbarContent
                        }
                    }
            }
            .tabItem {
                Label("Items", systemImage: "list.bullet")
            }
            .tag(0)
            
            // Categories Tab
            NavigationStack {
                categoriesContent
                    .navigationTitle("Categories")
            }
            .tabItem {
                Label("Categories", systemImage: "square.grid.2x2")
            }
            .tag(1)
            
            // Settings Tab
            NavigationStack {
                settingsContent
                    .navigationTitle("Settings")
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .tag(2)
        }
    }
    
    // MARK: - macOS Specific Content
    
    private var macOSSidebarContent: some View {
        List(selection: selectedMacView == .items ? $selectedItem : .constant(nil)) {
            Section("Navigation") {
                ForEach(MacViewType.allCases) { viewType in
                    MacNavigationRow(
                        viewType: viewType,
                        isSelected: selectedMacView == viewType,
                        action: {
                            selectedMacView = viewType
                            selectedItem = nil // Clear item selection when switching views
                        }
                    )
                }
            }
            
            if selectedMacView == .items {
                Section("Filters") {
                    Toggle("Favorites Only", isOn: $showFavoritesOnly)
                        .toggleStyle(.switch)
                    
                    Picker("Category", selection: $selectedCategory) {
                        Text("All Categories").tag(nil as DemoCategory?)
                        ForEach(DemoCategory.allCases) { category in
                            Label(category.rawValue, systemImage: category.icon)
                                .tag(category as DemoCategory?)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Items (\(filteredItems.count))") {
                    ForEach(filteredItems) { item in
                        Button(action: {
                            selectedItem = item
                        }) {
                            itemRow(item)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selectedItem?.id == item.id ? Color.accentColor.opacity(0.15) : Color.clear)
                                )
                        }
                        .buttonStyle(.plain)
                        .tag(item)
                    }
                }
            }
        }
        .listStyle(.sidebar)
    }
    
    private var macOSDetailContent: some View {
        Group {
            switch selectedMacView {
            case .items:
                if let selectedItem = selectedItem {
                    ItemDetailView(item: selectedItem)
                } else {
                    ContentUnavailableView(
                        "Select an Item",
                        systemImage: "sidebar.left",
                        description: Text("Choose an item from the sidebar to see its details")
                    )
                }
            case .categories:
                NavigationStack {
                    categoriesContent
                        .navigationTitle("Categories")
                }
            case .settings:
                NavigationStack {
                    settingsContent
                        .navigationTitle("Settings")
                }
            }
        }
    }
    
    // MARK: - Shared Content Components
    
    private var sidebarContent: some View {
        List(selection: $selectedItem) {
            Section("Filters") {
                Toggle("Favorites Only", isOn: $showFavoritesOnly)
                    .toggleStyle(.switch)
                
                Picker("Category", selection: $selectedCategory) {
                    Text("All Categories").tag(nil as DemoCategory?)
                    ForEach(DemoCategory.allCases) { category in
                        Label(category.rawValue, systemImage: category.icon)
                            .tag(category as DemoCategory?)
                    }
                }
                .pickerStyle(.menu)
            }
            
            Section("Items") {
                ForEach(filteredItems) { item in
                    itemRow(item)
                        .tag(item)
                }
            }
        }
        .listStyle(.sidebar)
    }
    
    private var listContent: some View {
        List {
            if !searchText.isEmpty {
                Section("Search Results") {
                    ForEach(filteredItems) { item in
                        NavigationLink(destination: ItemDetailView(item: item)) {
                            itemRow(item)
                        }
                    }
                }
            } else {
                Section("Filters") {
                    HStack {
                        Toggle("Favorites Only", isOn: $showFavoritesOnly)
                        Spacer()
                        Menu("Category") {
                            Button("All Categories") {
                                selectedCategory = nil
                            }
                            ForEach(DemoCategory.allCases) { category in
                                Button(action: {
                                    selectedCategory = category
                                }) {
                                    Label(category.rawValue, systemImage: category.icon)
                                }
                            }
                        }
                    }
                }
                
                Section("Items (\(filteredItems.count))") {
                    ForEach(filteredItems) { item in
                        NavigationLink(destination: ItemDetailView(item: item)) {
                            itemRow(item)
                        }
                    }
                }
            }
        }
    }
    
    private var categoriesContent: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: isMacLike ? 3 : 2), spacing: 16) {
            ForEach(DemoCategory.allCases) { category in
                categoryCard(category)
            }
        }
        .padding()
    }
    
    private var settingsContent: some View {
        Form {
            Section("Display") {
                Toggle("Show Favorites Only", isOn: $showFavoritesOnly)
                
                #if os(macOS)
                Picker("Sidebar Width", selection: .constant("Medium")) {
                    Text("Small").tag("Small")
                    Text("Medium").tag("Medium")
                    Text("Large").tag("Large")
                }
                #endif
            }
            
            Section("Data") {
                HStack {
                    Text("Total Items")
                    Spacer()
                    Text("\(DemoItem.samples.count)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Filtered Items")
                    Spacer()
                    Text("\(filteredItems.count)")
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Platform Info") {
                HStack {
                    Text("Platform")
                    Spacer()
                    Text(isMac ? "macOS" : "iOS")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Layout Style")
                    Spacer()
                    Text(isMac ? "Split View" : "Tab View")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    

    
    // MARK: - Helper Views
    
    private func itemRow(_ item: DemoItem) -> some View {
        HStack {
            Image(systemName: item.category.icon)
                .foregroundColor(item.category.color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(item.title)
                        .font(.headline)
                    if item.isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                Text(item.subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(item.dateCreated, style: .date)
                    .font(.caption2)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Text(item.category.rawValue)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(item.category.color.opacity(0.2))
                .foregroundColor(item.category.color)
                .cornerRadius(8)
        }
        .padding(.vertical, 2)
    }
    
    private func categoryCard(_ category: DemoCategory) -> some View {
        let count = DemoItem.samples.filter { $0.category == category }.count
        
        return VStack(spacing: 12) {
            Image(systemName: category.icon)
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(category.color)
            
            Text(category.rawValue)
                .font(.headline)
            
            Text("\(count) items")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(category.color.opacity(0.1))
                .stroke(category.color.opacity(0.3), lineWidth: 1)
        )
        .onTapGesture {
            selectedCategory = category
            if isMacLike {
                selectedMacView = .items // Switch to items view on macOS
            } else {
                selectedTab = 0 // Switch to items tab on iOS
            }
        }
    }
    
    // MARK: - Toolbar Content
    
    private var macOSToolbarContent: some View {
        HStack {
            Button(action: {
                showFavoritesOnly.toggle()
            }) {
                Image(systemName: showFavoritesOnly ? "heart.fill" : "heart")
            }
            .help("Toggle Favorites")
            
            Button(action: {
                selectedCategory = nil
                showFavoritesOnly = false
                searchText = ""
            }) {
                Image(systemName: "arrow.clockwise")
            }
            .help("Reset Filters")
        }
    }
    
    private var iOSToolbarContent: some View {
        Menu {
            Button(action: {
                showFavoritesOnly.toggle()
            }) {
                Label(showFavoritesOnly ? "Show All" : "Show Favorites", 
                      systemImage: showFavoritesOnly ? "heart.slash" : "heart")
            }
            
            Button(action: {
                selectedCategory = nil
                showFavoritesOnly = false
                searchText = ""
            }) {
                Label("Reset Filters", systemImage: "arrow.clockwise")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredItems: [DemoItem] {
        DemoItem.samples.filter { item in
            let matchesSearch = searchText.isEmpty || 
                item.title.localizedCaseInsensitiveContains(searchText) ||
                item.subtitle.localizedCaseInsensitiveContains(searchText)
            
            let matchesCategory = selectedCategory == nil || item.category == selectedCategory
            let matchesFavorites = !showFavoritesOnly || item.isFavorite
            
            return matchesSearch && matchesCategory && matchesFavorites
        }
        .sorted { $0.dateCreated > $1.dateCreated }
    }
}

// MARK: - Detail View
struct ItemDetailView: View {
    let item: DemoItem
    
    #if os(macOS)
    private let isMac = true
    #else
    private let isMac = false
    #endif
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Image(systemName: item.category.icon)
                        .font(.system(size: isMac ? 48 : 36, weight: .medium))
                        .foregroundColor(item.category.color)
                    
                    VStack(alignment: .leading) {
                        Text(item.title)
                            .font(isMac ? .largeTitle : .title)
                            .fontWeight(.bold)
                        
                        Text(item.subtitle)
                            .font(isMac ? .title2 : .headline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if item.isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.title2)
                    }
                }
                
                Divider()
                
                // Details
                VStack(alignment: .leading, spacing: 16) {
                    detailRow("Category", value: item.category.rawValue)
                    detailRow("Created", value: item.dateCreated.formatted(date: .abbreviated, time: .shortened))
                    detailRow("Favorite", value: item.isFavorite ? "Yes" : "No")
                    detailRow("Platform", value: isMac ? "macOS" : "iOS")
                }
                
                Divider()
                
                // Sample content
                VStack(alignment: .leading, spacing: 12) {
                    Text("Description")
                        .font(.headline)
                    
                    Text("This is a sample item demonstrating adaptive UI design across macOS and iOS platforms. The layout automatically adjusts based on the target platform while maintaining consistent functionality.")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text("Key Features:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.top)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        bulletPoint("Adaptive layout for different screen sizes")
                        bulletPoint("Platform-specific navigation patterns")
                        bulletPoint("Consistent search and filtering")
                        bulletPoint("Responsive design principles")
                    }
                }
                
                Spacer(minLength: 50)
            }
            .padding(isMac ? 24 : 16)
        }
        .navigationTitle(item.title)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func detailRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .fontWeight(.medium)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
    
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top) {
            Text("•")
                .foregroundColor(.secondary)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}

// MARK: - Preview
#Preview("Adaptive UI Demo") {
    AdaptiveUIDemo()
}

#Preview("Item Detail") {
    NavigationStack {
        ItemDetailView(item: DemoItem.samples[0])
    }
}

// MARK: - macOS System Settings Style Navigation Row
struct MacNavigationRow: View {
    let viewType: MacViewType
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: viewType.icon)
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 20, height: 20)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(viewType.rawValue)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColorForState)
            )
            .scaleEffect(isHovered && !isSelected ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isHovered)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    private var backgroundColorForState: Color {
        if isSelected {
            return .accentColor
        } else if isHovered {
            return Color.primary.opacity(0.08)
        } else {
            return .clear
        }
    }
}
