//
//  Gender.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 29/05/25.
//


import SwiftUI
import SwiftData
import Foundation

// MARK: - Gender Enum
enum Gender: String, CaseIterable, Codable {
    case male = "Male"
    case female = "Female"
    case other = "Other"
    
    var displayName: String {
        return self.rawValue
    }
}

// MARK: - Profile Model
@Model
class Profile {
    var firstName: String
    var lastName: String
    var dateOfBirth: Date
    var gender: Gender
    var email: String
    var createdAt: Date
    
    init(firstName: String, lastName: String, dateOfBirth: Date, gender: Gender, email: String) {
        self.firstName = firstName
        self.lastName = lastName
        self.dateOfBirth = dateOfBirth
        self.gender = gender
        self.email = email
        self.createdAt = Date()
    }
    
    var fullName: String {
        return "\(firstName) \(lastName)"
    }
    
    var age: Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: Date())
        return ageComponents.year ?? 0
    }
}

// MARK: - Profile Form View Model
@Observable
class ProfileFormViewModel {
    var firstName: String = ""
    var lastName: String = ""
    var dateOfBirth: Date = Date()
    var selectedGender: Gender = .male
    var email: String = ""
    var showingAlert = false
    var alertMessage = ""
    
    var isFormValid: Bool {
        return !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               isValidEmail(email)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    func clearForm() {
        firstName = ""
        lastName = ""
        dateOfBirth = Date()
        selectedGender = .male
        email = ""
    }
    
    func showAlert(message: String) {
        alertMessage = message
        showingAlert = true
    }
}

// MARK: - Profile Form View
// MARK: - Profile Form View
struct ProfileFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel = ProfileFormViewModel()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Optional: Custom drag indicator
                Capsule()
                    .fill(Color.red) // Change this to your preferred color
                    .frame(width: 40, height: 5)
                    .padding(.top, 8)

                Form {
                    Section(header: Text("Personal Information")) {
                        TextField("First Name", text: $viewModel.firstName)
                            .textContentType(.givenName)

                        TextField("Last Name", text: $viewModel.lastName)
                            .textContentType(.familyName)

                        DatePicker("Date of Birth",
                                   selection: $viewModel.dateOfBirth,
                                   in: ...Date(),
                                   displayedComponents: .date)

                        Picker("Gender", selection: $viewModel.selectedGender) {
                            ForEach(Gender.allCases, id: \.self) { gender in
                                Text(gender.displayName).tag(gender)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }

                    Section(header: Text("Contact Information")) {
                        TextField("Email", text: $viewModel.email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }

                    Section {
                        Button("Save Profile") {
                            saveProfile()
                        }
                        .disabled(!viewModel.isFormValid)
                    }
                }
                .alert("Profile", isPresented: $viewModel.showingAlert) {
                    Button("OK") {
                        if viewModel.alertMessage == "Profile saved successfully!" {
                            dismiss()
                        }
                    }
                } message: {
                    Text(viewModel.alertMessage)
                }
            }
            .navigationTitle("Add Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDragIndicator(.hidden) // hide system pill if desired
    }

    private func saveProfile() {
        let profile = Profile(
            firstName: viewModel.firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            lastName: viewModel.lastName.trimmingCharacters(in: .whitespacesAndNewlines),
            dateOfBirth: viewModel.dateOfBirth,
            gender: viewModel.selectedGender,
            email: viewModel.email.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        do {
            modelContext.insert(profile)
            try modelContext.save()
            viewModel.showAlert(message: "Profile saved successfully!")
        } catch {
            viewModel.showAlert(message: "Failed to save profile: \(error.localizedDescription)")
        }
    }
}


// MARK: - Profile List View
struct ProfileListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Profile.createdAt, order: .reverse) private var profiles: [Profile]
    @State private var showingAddProfile = false
    @State private var searchText = ""
    
    var filteredProfiles: [Profile] {
        if searchText.isEmpty {
            return profiles
        } else {
            return profiles.filter { profile in
                profile.firstName.localizedCaseInsensitiveContains(searchText) ||
                profile.lastName.localizedCaseInsensitiveContains(searchText) ||
                profile.email.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredProfiles) { profile in
                    ProfileRowView(profile: profile)
                }
                .onDelete(perform: deleteProfile)
            }
            .navigationTitle("Profiles")
            .searchable(text: $searchText, prompt: "Search profiles...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddProfile = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddProfile) {
                ProfileFormView()
//                    .presentationDragIndicator(.visible)
                
            }
            .overlay {
                if profiles.isEmpty {
                    ContentUnavailableView {
                        Label("No Profiles", systemImage: "person.3")
                    } description: {
                        Text("Add your first profile to get started")
                    } actions: {
                        Button("Add Profile") {
                            showingAddProfile = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
    }
    
    private func deleteProfile(at offsets: IndexSet) {
        for index in offsets {
            let profile = filteredProfiles[index]
            modelContext.delete(profile)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete profile: \(error)")
        }
    }
}

// MARK: - Profile Row View
struct ProfileRowView: View {
    let profile: Profile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(profile.fullName)
                .font(.headline)
            
            HStack {
                Label(profile.email, systemImage: "envelope")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(profile.age) years old")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Label(profile.gender.displayName, systemImage: genderIcon(for: profile.gender))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(profile.dateOfBirth, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
    
    private func genderIcon(for gender: Gender) -> String {
        switch gender {
        case .male:
            return "person"
        case .female:
            return "person.fill"
        case .other:
            return "person.2"
        }
    }
}

// MARK: - Main App
struct ProfileApp: App {
    var body: some Scene {
        WindowGroup {
            ProfileListView()
        }
        .modelContainer(for: Profile.self)
    }
}

// MARK: - Preview
#Preview {
    ProfileListView()
        .modelContainer(for: Profile.self, inMemory: true)
}
