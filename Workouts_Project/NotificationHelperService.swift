//
//  NotificationHelperService.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 28/05/25.
//

import Foundation
import SwiftUI

enum TextFieldType {
    case text
    case email
    case password
}

public struct InputField {
    var placeholder: String = ""
    var value: String = ""
    var type: TextFieldType = .text
}

public struct AlertModel {
    var title: String
    var message: String?
    var submitButtonText: String?
    var cancelButtonText: String = "OK"
    var inputField: InputField? = nil
    var onSubmitClick: (String) -> () = { _ in }
    var onCancelClick: () -> () = { }
}




class NotificationHelperService: ObservableObject {
    static let shared = NotificationHelperService()

    @Published var alertData: AlertModel? = nil

    var isAlertVisible: Bool {
        alertData != nil
    }

    func showAlert(_ alert: AlertModel) {
        DispatchQueue.main.async {
            self.alertData = alert
        }
    }

    func dismissAlert() {
        DispatchQueue.main.async {
            self.alertData = nil
        }
    }
}

struct AlertTestMainView: View {
    @StateObject private var alertService = NotificationHelperService.shared

    var body: some View {
        ZStack {
            AlertTestingView()
        }
        .presentAlert(alertData: $alertService.alertData)
    }
}

struct GlobalAlertModifier: ViewModifier {
    @Binding var alertData: AlertModel?

    var isAlertPresented: Binding<Bool> {
        Binding<Bool>(
            get: { alertData != nil },
            set: { newValue in
                if !newValue {
                    alertData = nil
                }
            }
        )
    }

    func body(content: Content) -> some View {
        content
            .alert(
                alertData?.title ?? "",
                isPresented: isAlertPresented
            ) {
                if let alert = alertData {
                    if let inputField = alert.inputField {
                        let binding = Binding(
                            get: { alertData?.inputField?.value ?? "" },
                            set: { alertData?.inputField?.value = $0 }
                        )

                        Group {
                            if inputField.type == .password {
                                SecureField(inputField.placeholder, text: binding)
                            } else {
                                TextField(inputField.placeholder, text: binding)
                                    .keyboardType(inputField.type == .email ? .emailAddress : .default)
                            }
                        }
                        .autocapitalization(.none)
                    }

                    Button(alert.cancelButtonText.uppercased()) {
                        alert.onCancelClick()
                        alertData = nil
                    }

                    if let submit = alert.submitButtonText {
                        Button(submit.uppercased()) {
                            let value = alertData?.inputField?.value ?? ""
                            alert.onSubmitClick(value)
                            alertData = nil
                        }
                        .keyboardShortcut(.defaultAction)
                    }
                }
            } message: {
                if let message = alertData?.message {
                    Text(message)
                }
            }
    }
}

extension View {
    public func presentAlert(alertData: Binding<AlertModel?>) -> some View {
        self.modifier(GlobalAlertModifier(alertData: alertData))
    }
}


import Combine

@Observable
class AlertTestingViewModel{
    var notificationHelperService = NotificationHelperService.shared

    
    func showAlert() {
        NotificationHelperService.shared.showAlert(
            AlertModel(
                title: "Confirm",
                message: "Do you want to continue?",
                submitButtonText: "Yes",
                cancelButtonText: "No",
                onSubmitClick: { value in
                    print("Confirmed with value: \(value)")
                },
                onCancelClick: {
                    print("Cancelled")
                }
            )
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.notificationHelperService.alertData = nil
        }
        
    }
    
    func showInputAlert() {
        let alertData = AlertModel(
                title: "Confirm",
                message: "Are you sure?",
                submitButtonText: "Yes",
                cancelButtonText: "No",
                inputField: InputField(placeholder: "Enter value", value: "", type: .password),
                onSubmitClick: { value in
                    print("Submitted value: \(value)")
                },
                onCancelClick: {
                    print("Cancelled")
                }
            )
            notificationHelperService.showAlert(alertData)
    }
}


struct AlertTestingView: View {
    @Bindable var viewModel = AlertTestingViewModel()
    var body: some View {
        VStack {
            Text("Hello, World!")
            
            Button("Show Alert") {
                viewModel.showAlert()
            }
            
            Button("Show Input Alert") {
                viewModel.showInputAlert()
            }
        }
    }
}

#Preview(body: {
    AlertTestMainView()
})

