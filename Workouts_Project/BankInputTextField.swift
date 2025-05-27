//
//  BankInputTextField.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 27/05/25.
//


import SwiftUI
import Combine

struct BankInputTextField: View {
    @Binding var value: String
    @State private var displayValue: String = ""
    
    let maxLen: Int
    let placeholder: String
    let isDisabled: Bool
    
    init(
        value: Binding<String>,
        maxLen: Int = 3,
        placeholder: String = "0.0",
        isDisabled: Bool = false
    ) {
        self._value = value
        self.maxLen = maxLen
        self.placeholder = placeholder
        self.isDisabled = isDisabled
    }
    
    var body: some View {
        TextField(placeholder, text: $displayValue)
            .keyboardType(.numberPad)
            .disabled(isDisabled)
            .onReceive(Just(displayValue)) { newValue in
                formatInput(newValue)
            }
            .onAppear {
                // Initialize with default value if empty
                if value.isEmpty {
                    displayValue = "0.0"
                    value = "0.0"
                } else {
                    displayValue = value
                }
            }
    }
    
    private func formatInput(_ input: String) {
        let formatted = bankInput(input)
        
        // Update display value if it changed
        if displayValue != formatted {
            displayValue = formatted
        }
        
        // Update the binding
        value = formatted
    }
    
    private func bankInput(_ input: String) -> String {
        // Handle empty or invalid input
        if input.isEmpty || input == "." {
            return "0.0"
        }
        
        // Extract only digits
        let digitsOnly = input.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        
        // Handle empty digits or just "0"
        if digitsOnly.isEmpty || digitsOnly == "0" {
            return "0.0"
        }
        
        // Remove leading zeros
        let trimmedDigits = digitsOnly.replacingOccurrences(of: "^0+", with: "", options: .regularExpression)
        
        if trimmedDigits.isEmpty {
            return "0.0"
        }
        
        // Limit to maxLen digits
        let limitedDigits = String(trimmedDigits.prefix(maxLen))
        let length = limitedDigits.count
        
        switch length {
        case 1:
            return "0.\(limitedDigits)"
        default:
            let beforeDecimal = limitedDigits.dropLast()
            let afterDecimal = limitedDigits.suffix(1)
            return "\(beforeDecimal).\(afterDecimal)"
        }
    }
}

// MARK: - Usage Example
struct BankInputTextFieldTestingView: View {
    @State private var inputValue: String = ""
    @State private var inputValue2: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading) {
                Text("Bank Input (Max 3 digits)")
                    .font(.headline)
                
                BankInputTextField(
                    value: $inputValue,
                    maxLen: 3,
                    placeholder: "0.0"
                )
                .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Text("Value: '\(inputValue)'")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading) {
                Text("Bank Input (Max 4 digits)")
                    .font(.headline)
                
                BankInputTextField(
                    value: $inputValue2,
                    maxLen: 4,
                    placeholder: "0.0"
                )
                .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Text("Value: '\(inputValue2)'")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Advanced Version with More Features
struct AdvancedBankInputTextField: View {
    @Binding var value: String
    @State private var displayValue: String = ""
    
    let maxLen: Int
    let placeholder: String
    let isDisabled: Bool
    let maxValue: Double?
    let allowWholeNumbers: Bool
    
    init(
        value: Binding<String>,
        maxLen: Int = 3,
        placeholder: String = "0.0",
        isDisabled: Bool = false,
        maxValue: Double? = nil,
        allowWholeNumbers: Bool = false
    ) {
        self._value = value
        self.maxLen = maxLen
        self.placeholder = placeholder
        self.isDisabled = isDisabled
        self.maxValue = maxValue
        self.allowWholeNumbers = allowWholeNumbers
    }
    
    var body: some View {
        TextField(placeholder, text: $displayValue)
            .keyboardType(.numberPad)
            .disabled(isDisabled)
            .onReceive(Just(displayValue)) { newValue in
                formatInput(newValue)
            }
            .onAppear {
                if value.isEmpty {
                    displayValue = "0.0"
                    value = "0.0"
                } else {
                    displayValue = value
                }
            }
    }
    
    private func formatInput(_ input: String) {
        let formatted: String
        
        if allowWholeNumbers {
            formatted = wholeNumberInput(input)
        } else {
            formatted = bankInput(input)
        }
        
        // Check against max value if specified
        if let maxVal = maxValue,
           let numValue = Double(formatted),
           numValue > maxVal {
            return // Don't update if exceeds max
        }
        
        if displayValue != formatted {
            displayValue = formatted
        }
        
        value = formatted
    }
    
    private func wholeNumberInput(_ input: String) -> String {
        let digitsOnly = input.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        
        if digitsOnly.isEmpty {
            return ""
        }
        
        let limitedDigits = String(digitsOnly.prefix(maxLen))
        return limitedDigits
    }
    
    private func bankInput(_ input: String) -> String {
        if input.isEmpty || input == "." {
            return "0.0"
        }
        
        let digitsOnly = input.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        
        if digitsOnly.isEmpty || digitsOnly == "0" {
            return "0.0"
        }
        
        // Remove leading zeros
        let trimmedDigits = digitsOnly.replacingOccurrences(of: "^0+", with: "", options: .regularExpression)
        
        if trimmedDigits.isEmpty {
            return "0.0"
        }
        
        let limitedDigits = String(trimmedDigits.prefix(maxLen))
        let length = limitedDigits.count
        
        switch length {
        case 1:
            return "0.\(limitedDigits)"
        default:
            let beforeDecimal = limitedDigits.dropLast()
            let afterDecimal = limitedDigits.suffix(1)
            return "\(beforeDecimal).\(afterDecimal)"
        }
    }
}

// MARK: - Usage Example for Advanced Version
struct AdvancedUsageExample: View {
    @State private var weight: String = ""
    @State private var height: String = ""
    @State private var wholeNumber: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading) {
                Text("Weight (Max 999.9)")
                AdvancedBankInputTextField(
                    value: $weight,
                    maxLen: 4,
                    placeholder: "0.0",
                    maxValue: 999.9
                )
                .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            VStack(alignment: .leading) {
                Text("Height (Max 99.9)")
                AdvancedBankInputTextField(
                    value: $height,
                    maxLen: 3,
                    placeholder: "0.0",
                    maxValue: 99.9
                )
                .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            VStack(alignment: .leading) {
                Text("Age (Whole Numbers)")
                AdvancedBankInputTextField(
                    value: $wholeNumber,
                    maxLen: 3,
                    placeholder: "0",
                    allowWholeNumbers: true
                )
                .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            Spacer()
        }
        .padding()
    }
}


#Preview(body: {
    BankInputTextFieldTestingView()
    AdvancedUsageExample()
})
