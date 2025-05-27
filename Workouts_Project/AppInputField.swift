//
//  ModularInputSystem.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 27/05/25.
//

import SwiftUI
import Combine

// MARK: - Input Types and Configuration

enum InputType {
    case text
    case number
    case password
    case bankInput
}

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

// MARK: - Bank Input Formatter

class BankInputFormatter: ObservableObject {
    private let config: TextInputConfig
    
    init(config: TextInputConfig) {
        self.config = config
    }
    
    var initialValue: String {
        config.allowWholeNumbers ? "0" : "0.0"
    }
    
    func formatInput(_ input: String) -> String {
        if config.allowWholeNumbers {
            return formatWholeNumber(input)
        } else {
            return formatDecimalNumber(input)
        }
    }
    
    func isValidValue(_ value: String) -> Bool {
        guard let numValue = Double(value),
              let maxVal = config.maxValue else {
            return true
        }
        return numValue <= maxVal
    }
    
    func shouldUpdateValue(from oldValue: String, to newValue: String) -> Bool {
        let formatted = formatInput(newValue)
        return isValidValue(formatted)
    }
    
    // MARK: - Private Formatting Methods
    
    private func formatDecimalNumber(_ input: String) -> String {
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
    
    private func formatWholeNumber(_ input: String) -> String {
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

// MARK: - Base Input Field

struct BaseInputField: View {
    // Configuration
    var inputType: InputType
    var keyboardType: UIKeyboardType
    var submitLabel: SubmitLabel
    var isDisabled: Bool
    
    // Bindings
    @Binding var value: String
    @FocusState.Binding var isFocused: Bool
    
    // Callbacks
    var onCommit: (() -> Void)?
    var onEditingChanged: ((Bool) -> Void)?
    
    // Internal state for password visibility
    @State private var isSecureTextVisible: Bool = false
    
    var body: some View {
        Group {
            if inputType == .password && !isSecureTextVisible {
                SecureField("", text: $value)
                    .submitLabel(submitLabel)
                    .disabled(isDisabled)
            } else {
                TextField("", text: $value)
                    .submitLabel(submitLabel)
                    .keyboardType(keyboardType)
                    .disabled(isDisabled)
            }
        }
        .focused($isFocused)
        .autocorrectionDisabled(true)
        .font(.system(size: 16))
        .foregroundColor(isDisabled ? Color.gray.opacity(0.5) : .primary)
        .onChange(of: isFocused) {
            onEditingChanged?(isFocused)
        }
        .onSubmit {
            onCommit?()
        }
        .overlay(
            HStack {
                Spacer()
                
                // Password visibility toggle
                if inputType == .password && !value.isEmpty && !isDisabled {
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
    }
}

// MARK: - App Input Field

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
    @FocusState private var fieldIsFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            VStack(alignment: .leading, spacing: 4) {
                // Main input container
                ZStack(alignment: .leading) {
                    // Floating label
                    Text(config.label)
                        .font((fieldIsFocused || !value.isEmpty) ? .system(size: 12, weight: .regular) : .system(size: 16, weight: .regular))
                        .foregroundColor(config.isDisabled ? Color.gray.opacity(0.5) : (config.errorMessage != nil ? Color.red : Color.gray.opacity(0.8)))
                        .offset(y: (fieldIsFocused || !value.isEmpty) ? -15 : 0)
                        .offset(x: 16)
                        .animation(.easeInOut(duration: 0.2), value: fieldIsFocused || !value.isEmpty)
                    
                    // Base input field
                    BaseInputField(
                        inputType: config.inputType,
                        keyboardType: keyboardTypeForInput,
                        submitLabel: config.submitLabel,
                        isDisabled: config.isDisabled,
                        value: $value,
                        isFocused: $fieldIsFocused,
                        onCommit: onCommit,
                        onEditingChanged: { focused in
                            isFocused = focused
                            onEditingChanged?(focused)
                        }
                    )
                    .padding(.top, (fieldIsFocused || !value.isEmpty) ? 8 : 0)
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
                    } else if config.inputType != .password {
                        Button(action: {
                            value = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.custom("Open Sans", size: 20))
                                .foregroundColor(config.errorMessage != nil ? .red : .gray)
                        }
                        .padding(.trailing, 8)
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
            }
            
            Text(config.errorMessage ?? "")
                .font(.caption)
                .foregroundColor(.red)
                .padding(.bottom, 4)
                .padding(.leading, 16)
                .frame(height: 15)
        }
    }
    
    private var keyboardTypeForInput: UIKeyboardType {
        switch config.inputType {
        case .number, .bankInput:
            return .numberPad
        default:
            return .default
        }
    }
}

// MARK: - Bank Input Field (Wrapper over AppInputField)

struct BankInputField: View {
    // Configuration
    var config: TextInputConfig
    
    // Bindings
    @Binding var value: String
    @Binding var isFocused: Bool
    
    // Callbacks
    var onCommit: (() -> Void)? = nil
    var onEditingChanged: ((Bool) -> Void)? = nil
    
    // Internal state and formatter
    @State private var displayValue: String = ""
    @StateObject private var formatter: BankInputFormatter
    
    init(
        config: TextInputConfig,
        value: Binding<String>,
        isFocused: Binding<Bool>,
        onCommit: (() -> Void)? = nil,
        onEditingChanged: ((Bool) -> Void)? = nil
    ) {
        self.config = config
        self._value = value
        self._isFocused = isFocused
        self.onCommit = onCommit
        self.onEditingChanged = onEditingChanged
        self._formatter = StateObject(wrappedValue: BankInputFormatter(config: config))
    }
    
    var body: some View {
        AppInputField(
            config: modifiedConfig,
            value: $displayValue,
            isFocused: $isFocused,
            onCommit: onCommit,
            onEditingChanged: onEditingChanged
        )
        .onReceive(Just(displayValue)) { newValue in
            handleValueChange(newValue)
        }
        .onAppear {
            initializeValue()
        }
    }
    
    // MARK: - Private Methods
    
    private var modifiedConfig: TextInputConfig {
        var modifiedConfig = config
        modifiedConfig.inputType = .bankInput
        return modifiedConfig
    }
    
    private func initializeValue() {
        if value.isEmpty {
            let initial = formatter.initialValue
            displayValue = initial
            value = initial
        } else {
            displayValue = value
        }
    }
    
    private func handleValueChange(_ newValue: String) {
        let formatted = formatter.formatInput(newValue)
        
        // Check if the new value is valid (doesn't exceed max)
        guard formatter.shouldUpdateValue(from: displayValue, to: newValue) else {
            return
        }
        
        // Update display value if it changed
        if displayValue != formatted {
            displayValue = formatted
        }
        
        // Update bound value
        value = formatted
    }
}

// MARK: - Testing View

struct TextInputFieldTestingView: View {
    @State var text: String = ""
    @State var password: String = ""
    @State var number: String = ""
    @State var disabledText: String = ""
    @State var bankWeightValue: String = ""
    @State var bankBodyFatValue: String = ""
    @State var bankExperienceValue: String = ""
    @State var bankDisabledValue: String = "42.5"
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Modular Input System Demo")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.bottom, 10)
                
                Group {
                    Text("AppInputField Examples")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
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
                            errorMessage: password.count < 6 && !password.isEmpty ? "Password is too short" : nil
                        ),
                        value: $password,
                        isFocused: .constant(true)
                    )
                    
                    // Number input example
                    AppInputField(
                        config: TextInputConfig(
                            label: "Phone Number",
                            placeholder: "Enter your phone number",
                            inputType: .number
                        ),
                        value: $number,
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
                }
                
                Divider()
                
                Group {
                    Text("BankInputField Examples (Built on AppInputField)")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Bank input examples
                    BankInputField(
                        config: TextInputConfig(
                            label: "Weight (kg)",
                            placeholder: "0.0",
                            inputType: .bankInput,
                            maxLength: 4,
                            maxValue: 999.9
                        ),
                        value: $bankWeightValue,
                        isFocused: .constant(false)
                    )
                    
                    BankInputField(
                        config: TextInputConfig(
                            label: "Body Fat %",
                            placeholder: "0.0",
                            inputType: .bankInput,
                            maxLength: 3,
                            maxValue: 99.9
                        ),
                        value: $bankBodyFatValue,
                        isFocused: .constant(false)
                    )
                    
                    BankInputField(
                        config: TextInputConfig(
                            label: "Years of Experience",
                            placeholder: "0",
                            inputType: .bankInput,
                            maxLength: 2,
                            allowWholeNumbers: true
                        ),
                        value: $bankExperienceValue,
                        isFocused: .constant(false)
                    )
                    
                    // Disabled bank input example
                    BankInputField(
                        config: TextInputConfig(
                            label: "Disabled Bank Input",
                            placeholder: "0.0",
                            inputType: .bankInput,
                            isDisabled: true,
                            maxLength: 3
                        ),
                        value: $bankDisabledValue,
                        isFocused: .constant(false)
                    )
                }
                
                Divider()
                
                // Display current values
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Values:")
                        .font(.headline)
                    
                    Group {
                        Text("Username: '\(text)'")
                        Text("Password: '\(String(repeating: "•", count: password.count))'")
                        Text("Phone: '\(number)'")
                        Text("Weight: '\(bankWeightValue)'")
                        Text("Body Fat: '\(bankBodyFatValue)'")
                        Text("Experience: '\(bankExperienceValue)'")
                        Text("Disabled Bank: '\(bankDisabledValue)'")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                // Formatting examples
                VStack(alignment: .leading, spacing: 8) {
                    Text("Formatting Examples:")
                        .font(.headline)
                    
                    Group {
                        Text("• Type '123' in Weight → displays '12.3'")
                        Text("• Type '4567' in Body Fat → displays '45.6' (max 3 digits)")
                        Text("• Type '25' in Experience → displays '25' (whole numbers)")
                        Text("• Weight max value: 999.9kg")
                        Text("• Body Fat max value: 99.9%")
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    TextInputFieldTestingView()
}
