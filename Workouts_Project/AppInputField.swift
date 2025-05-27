//
//  AppInputField.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 27/05/25.
//

import SwiftUI

// Input type enum to determine the field behavior
enum InputType {
    case text
    case number
    case password
}

// Configuration model for the input field
struct TextInputConfig {
    var label: String
    var placeholder: String
    var inputType: InputType
    var submitLabel: SubmitLabel = .next
    var errorMessage: String? = nil
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
    @FocusState private var fieldIsFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            VStack(alignment: .leading, spacing: 4) {
                // Main input container
                ZStack(alignment: .leading) {
                    // Floating label
                    Text(config.label)
                        .font((fieldIsFocused || !value.isEmpty) ? .system(size: 12, weight: .regular) : .system(size: 16, weight: .regular))
                        .foregroundColor((config.errorMessage != nil ? Color.red : Color.gray.opacity(0.8)))
                        .offset(y: (fieldIsFocused || !value.isEmpty) ? -15 : 0)
                        .offset(x: 16) // Add leading padding to align with error message
                        .animation(.easeInOut(duration: 0.2), value: fieldIsFocused || !value.isEmpty)
//                        .padding(.leading, 16)
                    // Input field
                    Group {
                        
                        if config.inputType == .password && !isSecureTextVisible {
                            SecureField("", text: $value)
                                .submitLabel(config.submitLabel)
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
                        } else {
                            TextField("", text: $value)
                                .submitLabel(config.submitLabel)
                                .keyboardType(config.inputType == .number ? .numberPad : .default)
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
                    .foregroundColor(.primary)
                    .padding(.top, (fieldIsFocused || !value.isEmpty) ? 8 : 0)
                    .padding(.leading, 16) // Add leading padding to the text input
    //                .placeholder(when: value.isEmpty && !fieldIsFocused) {
    //                    Text(config.placeholder)
    //                        .foregroundColor(.gray.opacity(0.6))
    //                        .font(.system(size: 16))
    //                }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 4) // Reduced horizontal padding to account for the new text padding
                .accentColor((config.errorMessage != nil ? Color.red : Color.gray.opacity(0.8)))
            }
            .frame(height: 56)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(10)
//            .overlay(
//                RoundedRectangle(cornerRadius: 10)
//                    .stroke(fieldIsFocused ? Color.blue : (config.errorMessage != nil ? Color.red : Color.gray.opacity(0.3)), lineWidth: fieldIsFocused || config.errorMessage != nil ? 2 : 1)
//            )
            .overlay(
                HStack {
                    Spacer()
                    
                    // Clear button
                    if !value.isEmpty {
                        Button(action: {
                            print("Clear button tapped")
                            value = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.custom("Open Sans", size: 20))
                                .foregroundColor(config.errorMessage != nil ? .red : .gray)
                                
                        }
                        .padding(.trailing, 8)
                    }
                    
                    // Password visibility toggle
                    if config.inputType == .password && !value.isEmpty {
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
                fieldIsFocused = true
            }
            .onChange(of: isFocused) {
                fieldIsFocused = isFocused
            }
            .onAppear {
                fieldIsFocused = isFocused
            }
            if let errorMessage = config.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.bottom, 4)
                    .padding(.leading, 16) // Align with the label
            }
        }

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

struct textInputFieldTestingView: View {
    @State var text: String = ""
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
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .previewLayout(.sizeThatFits)
    }
}

#Preview(body: {
    textInputFieldTestingView()
})
