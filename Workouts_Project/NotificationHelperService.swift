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
    var placeHolder: String = ""
    var value: String = ""
    var inputField: Bool = false
    var isEmailField: Bool = false
    var onSubmitClick: (String)->() = { _ in }
    var onCancelClick: ()->() = { }
}

struct AlertModifier: ViewModifier {
    @Binding var showAlert: Bool
    @Binding var alertData: AlertModel

    func body(content: Content) -> some View {
        content
            .alert(alertData.title, isPresented: $showAlert) {
                // Input field (optional)
                if alertData.inputField {
                    TextField(alertData.placeHolder, text: $alertData.value)
                        .keyboardType(alertData.isEmailField ? .emailAddress : .default)
                        .autocapitalization(.none)
                }

                // Cancel button
                Button(alertData.cancelButtonText.uppercased()) {
                    alertData.onCancelClick()
                }

                // Submit button
                if let submit = alertData.submitButtonText {
                    Button(submit.uppercased()) {
                        alertData.inputField = false // optional reset
                        alertData.onSubmitClick(alertData.value)
                    }
                    .keyboardShortcut(.defaultAction)
                }
            } message: {
                if let message = alertData.message {
                    Text(message)
                }
            }
    }
}





extension View {
    public func presentAlert(showAlert: Binding<Bool>, alertData: Binding<AlertModel>) -> some View {
        self.modifier(AlertModifier(showAlert: showAlert, alertData: alertData))
    }
}


class NotificationHelperService: ObservableObject {
    @Published var alertData: AlertModel? = nil
    static let shared = NotificationHelperService()
}
import Combine

@Observable
class AlertTestingViewModel{
    var notificationHelperService = NotificationHelperService.shared
    var alertData: AlertModel = AlertModel(title: "", message: nil, submitButtonText: nil, cancelButtonText: "OK", placeHolder: "", value: "")
    var canShowAlert: Bool = false
    private var cancellables = Set<AnyCancellable>()
    init() {
        // Initialize with current values from AccountService
        notificationHelperService.$alertData
            .sink(receiveValue: { data in
                print("Received alert data: \(String(describing: data))")
                if let data = data {
                    self.alertData = data
                }
                self.canShowAlert = data != nil
            })
            .store(in: &cancellables)
    }
    
    func showAlert() {
        let alertData = AlertModel(
            title: "Confirm",
            message: "Are you sure?",
            submitButtonText: "Yes",
            cancelButtonText: "No",
            onSubmitClick: { value in
                // handle submit
               // self.alertData = nil
            },
            onCancelClick: {
                // handle cancel
                // self.alertData = nil
            }
        )
        
        DispatchQueue.main.async {
            self.notificationHelperService.alertData = alertData
        }
        
    }
    
    func showInputAlert() {
        let alertData = AlertModel(
            title: "Confirm",
            message: "Are you sure?",
            submitButtonText: "Yes",
            cancelButtonText: "No",
            placeHolder: "Enter value",
            value: "",
            inputField: true,
            onSubmitClick: { value in
                print("Submitted value: \(value)")
                // handle submit
            },
            onCancelClick: {
                // handle cancel
            }
        )
        notificationHelperService.alertData = alertData
    }

    
}


struct AlertTestingView: View {
    @Bindable var viewModel = AlertTestingViewModel()
    var body: some View {
        VStack {
            Text("Hello, World!")
               
            Button("Show Alert") {
                viewModel.showInputAlert()
            }
        }
        .presentAlert(showAlert: $viewModel.canShowAlert, alertData: $viewModel.alertData)
    }
}

#Preview(body: {
    AlertTestingView()
})

