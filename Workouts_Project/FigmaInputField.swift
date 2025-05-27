//
//  FigmaInputField.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 26/05/25.
//

enum FieldFocusType {
    case firstName, lastName ,email, password, confirmPassword, currentPassword
}

import SwiftUI

struct FigmaInputField: View {
    var label: String = "label"
    @State private var inputText: String = ""
    @State private var isEditing: Bool = false // Add this state to track editing
    @FocusState private var isInputActive: Bool
    @FocusState private var focus : FieldFocusType?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) { // Corresponds to layout_O355FK (column layout with 10px gap)
            HStack(spacing: 4) { // Corresponds to layout_6A2Q11 (row layout with 4px gap)
                ZStack(alignment: .leading) { // Use ZStack to layer label and input
                    
                    Text(label.lowercased()) // Corresponds to Label text
                        .font((isEditing || !inputText.isEmpty) ? .custom("Open Sans", size: 13).weight(.regular) : .custom("Open Sans", size: 16).weight(.regular)) // Shrink font when editing or has text
                        .foregroundColor((isEditing || !inputText.isEmpty) ? Color(hex: "7B726E") : Color(hex: "7B726E")) // Label color
                        .offset(y: (isEditing || !inputText.isEmpty) ? -16 : 0) // Move up when editing or has text
                        .animation(.easeInOut(duration: 0.2), value: isEditing || !inputText.isEmpty) // Animate the movement
                    TextField("", text: $inputText, onEditingChanged: { editing in
                        // Use onEditingChanged callback to track editing state
                        isEditing = editing
                        print("Editing changed: \(editing)")
                    }) // Corresponds to Input text
                        .focused($isInputActive, equals: true)
                        .onTapGesture {
                            print("Input tapped") // Debug print
                            isInputActive = true } // Ensure focus is set on tap
                        .font(.custom("Open Sans", size: 16).weight(.regular)) // style_0GELWY
                        .foregroundColor(Color(hex: "1D1B20")) // fill_3OVY8Y
                        .disableAutocorrection(true) // Common for input fields
                        .padding(.top, (isEditing || !inputText.isEmpty) ? 8 : 0) // Add padding to input when label moves up
                        .focused($focus , equals: .email)
                        .onChange(of: focus) {
                            print("Input focus changed: ") // Debug print
                        }
                }
                .padding(.vertical, 4) // Corresponds to padding in layout_G55EPR
                .padding(.leading, 16) // Apply leading padding here

                // Trailing icon (Icon button)
                Button(action: {
                    // Action for the trailing icon button
                    print("Trailing icon tapped")
                }) {
                    Image(systemName: "xmark.circle.fill") // Using a placeholder SF Symbol for the close icon
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24) // Corresponds to icon size layout_IEA56Y
                        .foregroundColor(Color(hex: "1565C0")) // Corresponds to fill_CSFRU7 or stroke_ON6RAP (blue color)
                }
                .frame(width: 40, height: 40) // Corresponds to layout_WNU5EF (Icon button content size)
                .background(Color(hex: "FFFFFF")) // Corresponds to fill_553Y3P
                .clipShape(Circle()) // Corresponds to borderRadius 100px in layout_WNU5EF
                .buttonStyle(BorderlessButtonStyle()) // To remove default button styling
                .padding(.trailing, 4) // Corresponds to padding in layout_6A2Q11
            }
            .padding(.leading, 16) // Corresponds to padding in layout_6A2Q11
            .padding(.vertical, 4) // Corresponds to padding in layout_6A2Q11
        }
        .frame(height: 56) // Corresponds to layout_O355FK height
        .background(Color(hex: "FFFFFF")) // Corresponds to fill_553Y3P
        .cornerRadius(10) // Corresponds to borderRadius 10px
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke((isEditing || isInputActive) ? Color(hex: "1565C0") : Color.gray.opacity(0.2), lineWidth: (isEditing || isInputActive) ? 2 : 1) // Thicker/colored border when editing or active
        )
        .onTapGesture {
            isInputActive = true
        }
    }
}

// Helper to create Color from hex string
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0) // Default to white
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct FigmaInputField_Previews: PreviewProvider {
    static var previews: some View {
        FigmaInputField()
    }
}


struct OnEditingChangedDemo:View{
    @State var name = ""
    var body: some View{
        List{
            TextField("name:",text: $name,onEditingChanged: getFocus)
            CustomSecureField(text: $name, placeholder: name, onCommit: {
                
            }, onEditingChanged: getFocus)
                
        }
    }

    func getFocus(focused:Bool) {
        print("get focus:\(focused ? "true" : "false")")
    }
}

import SwiftUI

struct CustomSecureField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var onCommit: () -> Void
    var onEditingChanged: (Bool)->() = { _ in }
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.isSecureTextEntry = true
        textField.placeholder = placeholder
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textDidChange), for: .editingChanged)
        textField.addTarget(context.coordinator, action: #selector(Coordinator.editingDidBegin), for: .editingDidBegin)
        textField.addTarget(context.coordinator, action: #selector(Coordinator.editingDidEnd), for: .editingDidEnd)
        textField.addTarget(context.coordinator, action: #selector(Coordinator.commitAction), for: .editingDidEndOnExit)
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onCommit: onCommit, onEditingChanged: onEditingChanged)
    }
    
    class Coordinator: NSObject {
        @Binding var text: String
        var onCommit: () -> Void
        var onEditingChanged: (Bool)->() = { _ in }
        
        init(text: Binding<String>, onCommit: @escaping () -> Void, onEditingChanged: @escaping (Bool)->() = { _ in }) {
            _text = text
            self.onCommit = onCommit
            self.onEditingChanged = onEditingChanged
        }
        
        @objc func textDidChange(_ textField: UITextField) {
            text = textField.text ?? ""
        }
        
        @objc func editingDidBegin() {
            // Called when editing begins
            onEditingChanged(true)
        }
        
        @objc func editingDidEnd() {
            // Called when editing ends
            onEditingChanged(false)
        }
        
        @objc func commitAction() {
            // Called when user hit return in keyboard
            onCommit()
        }
        
        
    }
}
