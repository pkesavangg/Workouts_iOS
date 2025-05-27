//
//  AppInputField.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 27/05/25.
//

import SwiftUI
import Combine

// Input type enum to determine the field behavior
enum InputType {
    case text
    case number
    case password
    case bankInput // New bank input type
}

// Configuration model for the input field
struct TextInputConfig {
    var label: String
    var placeholder: String
    var inputType: InputType
    var submitLabel: SubmitLabel = .next
    var errorMessage: String? = nil
    var isDisabled: Bool = false
    
    // Bank input specific properties
    var maxLength: Int = 3
    var maxValue: Double? = nil
    var allowWholeNumbers: Bool = false
}

struct AppInputField: View {
    // Configuration
    var config: TextInputConfig
    
    // Bindings
    @Binding var value: String
    @Binding var isFocused: Bool
    
    // Callbacks
    var onCommit: (() -> Void)? = nil
    var onEditingChanged: ((Bool) -> Void)? = nil
    
    // Internal state
    @State private var isSecureTextVisible: Bool = false
    @State private var displayValue: String = ""
    @FocusState private var fieldIsFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            VStack(alignment: .leading, spacing: 4) {
                // Main input container
                ZStack(alignment: .leading) {
                    // Floating label
                    Text(config.label)
                        .font((fieldIsFocused || !getCurrentValue().isEmpty) ? .system(size: 12, weight: .regular) : .system(size: 16, weight: .regular))
                        .foregroundColor(config.isDisabled ? Color.gray.opacity(0.5) : (config.errorMessage != nil ? Color.red : Color.gray.opacity(0.8)))
                        .offset(y: (fieldIsFocused || !getCurrentValue().isEmpty) ? -15 : 0)
                        .offset(x: 16)
                        .animation(.easeInOut(duration: 0.2), value: fieldIsFocused || !getCurrentValue().isEmpty)
                    
                    // Input field
                    Group {
                        if config.inputType == .password && !isSecureTextVisible {
                            SecureField("", text: $value)
                                .submitLabel(config.submitLabel)
                                .disabled(config.isDisabled)
                                .onChange(of: fieldIsFocused) { newValue in
                                    print("Field focus changed: \(newValue)")
                                    isFocused = newValue
                                    if let onEditingChanged = onEditingChanged {
                                        onEditingChanged(newValue)
                                    }
                                }
                                .onSubmit {
                                    if let onCommit = onCommit {
                                        onCommit()
                                    }
                                }
                        } else if config.inputType == .bankInput {
                            // Bank input field
                            TextField("", text: $displayValue)
                                .submitLabel(config.submitLabel)
                                .keyboardType(.numberPad)
                                .disabled(config.isDisabled)
                                .onChange(of: fieldIsFocused) { newValue in
                                    isFocused = newValue
                                    if let onEditingChanged = onEditingChanged {
                                        onEditingChanged(newValue)
                                    }
                                }
                                .onSubmit {
                                    if let onCommit = onCommit {
                                        onCommit()
                                    }
                                }
                                .onReceive(Just(displayValue)) { newValue in
                                    formatBankInput(newValue)
                                }
                        } else {
                            TextField("", text: $value)
                                .submitLabel(config.submitLabel)
                                .keyboardType(config.inputType == .number ? .numberPad : .default)
                                .disabled(config.isDisabled)
                                .onChange(of: fieldIsFocused) { newValue in
                                    isFocused = newValue
                                    if let onEditingChanged = onEditingChanged {
                                        onEditingChanged(newValue)
                                    }
                                }
                                .onSubmit {
                                    if let onCommit = onCommit {
                                        onCommit()
                                    }
                                }
                        }
                    }
                    .focused($fieldIsFocused)
                    .autocorrectionDisabled(true)
                    .font(.system(size: 16))
                    .foregroundColor(config.isDisabled ? Color.gray.opacity(0.5) : .primary)
                    .padding(.top, (fieldIsFocused || !getCurrentValue().isEmpty) ? 8 : 0)
                    .padding(.leading, 16)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
                .accentColor((config.errorMessage != nil ? Color.red : Color.gray.opacity(0.8)))
            }
            .frame(height: 56)
            .background(config.isDisabled ? Color.gray.opacity(0.1) : Color(UIColor.systemBackground))
            .cornerRadius(10)
            .overlay(
                HStack {
                    Spacer()
                    
                    // Disabled indicator or Clear button
                    if config.isDisabled {
                        Image(systemName: "xmark.circle.fill")
                            .font(.custom("Open Sans", size: 20))
                            .foregroundColor(.gray.opacity(0.5))
                            .padding(.trailing, 12)
                    } else if !getCurrentValue().isEmpty {
                        Button(action: {
                            print("Clear button tapped")
                            clearValue()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.custom("Open Sans", size: 20))
                                .foregroundColor(config.errorMessage != nil ? .red : .gray)
                        }
                        .padding(.trailing, 8)
                    }
                    
                    // Password visibility toggle
                    if config.inputType == .password && !value.isEmpty && !config.isDisabled {
                        Button(action: {
                            isSecureTextVisible.toggle()
                        }) {
                            Image(systemName: isSecureTextVisible ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.gray)
                        }
                        .padding(.trailing, 12)
                    }
                }
            )
            .onTapGesture {
                if !config.isDisabled {
                    fieldIsFocused = true
                }
            }
            .onChange(of: isFocused) {
                fieldIsFocused = isFocused
            }
            .onAppear {
                fieldIsFocused = isFocused
                initializeBankInput()
            }
            
            if let errorMessage = config.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.bottom, 4)
                    .padding(.leading, 16)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentValue() -> String {
        return config.inputType == .bankInput ? displayValue : value
    }
    
    private func clearValue() {
        if config.inputType == .bankInput {
            displayValue = "0.0"
            value = "0.0"
        } else {
            value = ""
        }
    }
    
    private func initializeBankInput() {
        guard config.inputType == .bankInput else { return }
        
        if value.isEmpty {
            displayValue = "0.0"
            value = "0.0"
        } else {
            displayValue = value
        }
    }
    
    private func formatBankInput(_ input: String) {
        guard config.inputType == .bankInput else { return }
        
        let formatted: String
        
        if config.allowWholeNumbers {
            formatted = wholeNumberInput(input)
        } else {
            formatted = bankInput(input)
        }
        
        // Check against max value if specified
        if let maxVal = config.maxValue,
           let numValue = Double(formatted),
           numValue > maxVal {
            return // Don't update if exceeds max
        }
        
        if displayValue != formatted {
            displayValue = formatted
        }
        
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
        
        // Limit to maxLength digits
        let limitedDigits = String(trimmedDigits.prefix(config.maxLength))
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
    
    private func wholeNumberInput(_ input: String) -> String {
        let digitsOnly = input.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        
        if digitsOnly.isEmpty {
            return "0"
        }
        
        let trimmedDigits = digitsOnly.replacingOccurrences(of: "^0+", with: "", options: .regularExpression)
        
        if trimmedDigits.isEmpty {
            return "0"
        }
        
        let limitedDigits = String(trimmedDigits.prefix(config.maxLength))
        return limitedDigits
    }
}

// Extension for placeholder functionality
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

struct TextInputFieldTestingView: View {
    @State var text: String = ""
    @State var weightValue: String = ""
    @State var heightValue: String = ""
    @State var ageValue: String = ""
    @State var disabledText: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // Text input example
            AppInputField(
                config: TextInputConfig(
                    label: "Username",
                    placeholder: "Enter your username",
                    inputType: .text
                ),
                value: $text,
                isFocused: .constant(false)
            )
            
            // Password input example
            AppInputField(
                config: TextInputConfig(
                    label: "Password",
                    placeholder: "Enter your password",
                    inputType: .password,
                    submitLabel: .done,
                    errorMessage: "Password is too short"
                ),
                value: $text,
                isFocused: .constant(false)
            )
            
            // Number input example
            AppInputField(
                config: TextInputConfig(
                    label: "Age",
                    placeholder: "Enter your age",
                    inputType: .number
                ),
                value: $text,
                isFocused: .constant(false)
            )
            
            // Bank input examples
            AppInputField(
                config: TextInputConfig(
                    label: "Weight (kg)",
                    placeholder: "0.0",
                    inputType: .bankInput,
                    maxLength: 4,
                    maxValue: 999.9
                ),
                value: $weightValue,
                isFocused: .constant(false)
            )
            
            AppInputField(
                config: TextInputConfig(
                    label: "Height (cm)",
                    placeholder: "0.0",
                    inputType: .bankInput,
                    maxLength: 3,
                    maxValue: 99.9
                ),
                value: $heightValue,
                isFocused: .constant(false)
            )
            
            AppInputField(
                config: TextInputConfig(
                    label: "Years of Experience",
                    placeholder: "0",
                    inputType: .bankInput,
                    maxLength: 2,
                    allowWholeNumbers: true
                ),
                value: $ageValue,
                isFocused: .constant(false)
            )
            
            // Disabled input example
            AppInputField(
                config: TextInputConfig(
                    label: "Disabled Input",
                    placeholder: "This field is disabled",
                    inputType: .text,
                    isDisabled: true
                ),
                value: $disabledText,
                isFocused: .constant(false)
            )
            
            // Disabled bank input example
            AppInputField(
                config: TextInputConfig(
                    label: "Disabled Bank Input",
                    placeholder: "0.0",
                    inputType: .bankInput,
                    isDisabled: true,
                    maxLength: 3
                ),
                value: $weightValue,
                isFocused: .constant(false)
            )
            
            // Display current values
            VStack(alignment: .leading, spacing: 4) {
                Text("Values:")
                    .font(.headline)
                Text("Weight: '\(weightValue)'")
                Text("Height: '\(heightValue)'")
                Text("Experience: '\(ageValue)'")
                Text("Disabled: '\(disabledText)'")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    TextInputFieldTestingView()
}
