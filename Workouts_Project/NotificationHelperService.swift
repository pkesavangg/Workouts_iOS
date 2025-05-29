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

public struct ToastModel {
    var title: String
    var message: String?
    var buttonView: AnyView?
    var onClick: () -> Void = {}
    var duration: Double = 3
}



class NotificationHelperService: ObservableObject {
    static let shared = NotificationHelperService()

    @Published var alertData: AlertModel? = nil
    @Published var toastData: ToastModel? = nil

    var isAlertVisible: Bool {
        alertData != nil
    }
    
    var isToastVisible: Bool {
        toastData != nil
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

    func showToast(_ data: ToastModel) {
        DispatchQueue.main.async {
            self.toastData = data
        }
    }

    func dismissToast() {
        DispatchQueue.main.async {
            self.toastData = nil
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
        .presentToast(data: $alertService.toastData)
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

struct ToastModifier: ViewModifier {
    @Binding var toastData: ToastModel?

    @State private var offset = CGSize.zero
    @State private var isDragging = false
    @State private var timer: DispatchSourceTimer?

    var isVisible: Binding<Bool> {
        Binding(
            get: { toastData != nil },
            set: { newValue in
                if !newValue {
                    toastData = nil
                }
            }
        )
    }

    func body(content: Content) -> some View {
        ZStack {
            content
            VStack {
                if isVisible.wrappedValue, let data = toastData {
                    HStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(data.title)
                                .font(.callout)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .truncationMode(.tail)

                            if let subtitle = data.message {
                                Text(subtitle)
                                    .font(.callout)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                        }

                        Spacer()

                        if let button = data.buttonView {
                            Button {
                                data.onClick()
                                toastData = nil
                            } label: {
                                button
                                    .foregroundColor(.white)
                                    .padding(.trailing, 5)
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(width: min(UIScreen.main.bounds.width * 0.9, 550))
                    .padding(12)
                    .background(Color.blue)
                    .cornerRadius(15)
                    .padding()
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                offset.width = gesture.translation.width
                                isDragging = true
                            }
                            .onEnded { _ in
                                withAnimation {
                                    toastData = nil
                                    offset = .zero
                                    isDragging = false
                                }
                                timer?.cancel()
                                timer = nil
                            }
                    )
                    .onAppear {
                        timer?.cancel()
                        let newTimer = DispatchSource.makeTimerSource()
                        newTimer.schedule(deadline: .now() + data.duration)
                        newTimer.setEventHandler {
                            DispatchQueue.main.async {
                                withAnimation {
                                    toastData = nil
                                }
                            }
                        }
                        newTimer.resume()
                        timer = newTimer
                    }
                }

                Spacer()
            }
        }
    }
}


extension View {
    public func presentAlert(alertData: Binding<AlertModel?>) -> some View {
        self.modifier(GlobalAlertModifier(alertData: alertData))
    }
    
    public func presentToast(data: Binding<ToastModel?>) -> some View {
        self.modifier(ToastModifier(toastData: data))
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
    
    func showToast() {
        NotificationHelperService.shared.showToast(
            ToastModel(
                title: "Success",
                message: "Your action was completed!",
                duration: 2
            )
        )
    }
    
    func showToastWithButton() {
        NotificationHelperService.shared.showToast(
            ToastModel(
                title: "Success",
                message: "Your action was completed!",
                buttonView: AnyView(
                    Button("Undo") {
                        print("Undo action")
                    }
                ),
                duration: 2
            )
        )
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
            
            Button("Show Toast") {
                viewModel.showToast()
            }
            
            Button("Show Toast with Button") {
                viewModel.showToastWithButton()
            }
        }
    }
}

#Preview(body: {
    AlertTestMainView()
})

