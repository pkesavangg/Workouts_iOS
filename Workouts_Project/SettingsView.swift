//
//  SettingsView.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 18/06/25.
//


import SwiftUI

import SwiftUI

struct SettingsView: View {
    var body: some View {
        ZStack {                       // ➊ put a color at the very back
            Color.red.opacity(0.3)
                .ignoresSafeArea()

            List {
                ProfileSection()
                TitleSectionView()
                    .padding(.bottom, -30)
                AccountSettingsSection()
                ProfileSettingsSection()
                AppSettingsSection()
                SupportSection()
                DestructiveActionsSection()
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)   // ➋ hide List’s own background
        }
    }
}

struct SupportSection: View {
    var body: some View {
        Section(header: Text("")) {
            SettingsRow(title: "Help & Customer Service", value: nil)
            SettingsRow(title: "Privacy Policy", value: nil)
            SettingsRow(title: "Terms of Service", value: nil)
            SettingsRow(title: "GreaterGoods.com", value: nil)
        }
    }
}

struct TitleSectionView: View {
    var body: some View {
        VStack(spacing: 10) {
            Text("Kristin")
                .font(.title2)
                .bold()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
}

struct ProfileSection: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "person.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(.blue)

            Text("Kristin")
                .font(.title2)
                .bold()

            Text("kstazrad@gmail.com")
                .font(.subheadline)
                .foregroundColor(.gray)

            Button("Edit") {
                // Action
            }
            .frame(maxWidth: 120)
            .padding(.vertical, 6)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .listRowBackground(Color.clear)
    }
}
struct SettingsRow: View {
    let title: String
    let value: String?

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            if let value = value {
                Text(value)
                    .foregroundColor(.gray)
            }
            Image(systemName: "chevron.right")
                .foregroundColor(.blue)
        }
    }
}

struct AccountSettingsSection: View {
    var body: some View {
        Section(header:
            Text("Account Settings")
                .font(.system(.title3, design: .default).bold())
                .foregroundColor(.red)
                .padding(.bottom, 4)
        ) {
            SettingsRow(title: "Add & Edit Scales", value: nil)
            SettingsRow(title: "Integrations", value: nil)
            SettingsRow(title: "Export Data", value: nil)
            SettingsRow(title: "Change Password", value: nil)
        }
    }
}
struct ProfileSettingsSection: View {
    var body: some View {
        Section(header: Text("Profile Settings")) {
            SettingsRow(title: "Goal Setting", value: nil)
            SettingsRow(title: "Biological Sex", value: "Female")
            SettingsRow(title: "Activity Level", value: "Normal")
            SettingsRow(title: "Height", value: "5'7\"")
            SettingsRow(title: "Unit Type", value: "lbs & feet")
            SettingsRow(title: "Weightless", value: "Off")
        }
    }
}
struct AppSettingsSection: View {
    @State private var isAppearancePickerPresented = false
    @State private var appearanceMode: AppearanceMode = .system
    @State private var showingAppearanceDialog = false

    var body: some View {
        Section(header: Text("App Settings")) {
            SettingsRow(title: "Notifications", value: "On")
            SettingsRow(title: "Messages", value: nil)
            SettingsRow(title: "Streaks", value: "On")
            SettingsRow(title: "App Permissions", value: nil)
            Button {
                showingAppearanceDialog = true
            } label: {
                SettingsRow(title: "Appearance", value: appearanceMode.rawValue)
            }
            .confirmationDialog(
                "Choose Appearance",
                isPresented: $showingAppearanceDialog,
                titleVisibility: .visible
            ) {
                ForEach(AppearanceMode.allCases, id: \.self) { mode in
                    Button(mode.rawValue) {
                        appearanceMode = mode
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
        .sheet(isPresented: $isAppearancePickerPresented) {
            AppearancePickerView(selectedAppearance: $appearanceMode)
        }
    }
}
struct DestructiveActionsSection: View {
    var body: some View {
        Section {
            Button("Log Out") {
                // Log out action
            }
            .foregroundColor(.primary)

            Button("Delete Account") {
                // Delete action
            }
            .foregroundColor(.red)
        }
    }
}
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
import SwiftUI

/// Enum representing the different appearance modes available in the app
enum AppearanceMode: String, CaseIterable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil // nil means follow system setting
        }
    }
}

struct AppearancePickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedAppearance: AppearanceMode
    @State private var tempSelection: AppearanceMode

    init(selectedAppearance: Binding<AppearanceMode>) {
        self._selectedAppearance = selectedAppearance
        self._tempSelection = State(initialValue: selectedAppearance.wrappedValue)
    }

    var body: some View {
        NavigationView {
            Form {
                Picker("Appearance", selection: $tempSelection) {
                    ForEach(AppearanceMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.inline)
            }
            .navigationTitle("Appearance")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        selectedAppearance = tempSelection
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

