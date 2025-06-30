//
//  TestFormView.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 14/06/25.
//


import SwiftUI

struct TestFormView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var age = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var city = ""
    @State private var zipCode = ""
    @State private var gender = "Male"
    @State private var subscribeToNewsletter = false
    @State private var acceptTerms = false
    @State private var birthDate = Date()
    @State private var selectedCountry = "USA"
    
    let genders = ["Male", "Female", "Other"]
    let countries = ["USA", "Canada", "UK", "Germany", "India"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Info")) {
                    TextField("Name", text: $name)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                    SecureField("Password", text: $password)
                    TextField("Age", text: $age)
                        .keyboardType(.numberPad)
                    DatePicker("Birth Date", selection: $birthDate, displayedComponents: .date)
                    Picker("Gender", selection: $gender) {
                        ForEach(genders, id: \.self) {
                            Text($0)
                        }
                    }
                }

                Section(header: Text("Contact Details")) {
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Address", text: $address)
                    TextField("City", text: $city)
                    TextField("ZIP Code", text: $zipCode)
                        .keyboardType(.numbersAndPunctuation)
                    Picker("Country", selection: $selectedCountry) {
                        ForEach(countries, id: \.self) {
                            Text($0)
                        }
                    }
                }

                Section(header: Text("Preferences")) {
                    Toggle("Subscribe to Newsletter", isOn: $subscribeToNewsletter)
                    Toggle("Accept Terms and Conditions", isOn: $acceptTerms)
                }
                
                Section {
                    Button("Submit") {
                        // Handle form submission
                        print("Form submitted")
                    }
                }
            }
            .navigationTitle("Test Form")
        }
    }
}
