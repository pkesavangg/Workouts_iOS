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

public struct LoaderModel {
    var text: String?
}

public struct ModalViewState {
    var contentView: AnyView = AnyView(EmptyView())
    var backdropDismiss: Bool = false
}

class NotificationHelperService: ObservableObject {
    static let shared = NotificationHelperService()

    @Published var alertData: AlertModel? = nil
    @Published var toastData: ToastModel? = nil
    @Published var loaderData: LoaderModel? = nil
    @Published var modalViewData: ModalViewState? = nil


    var isAlertVisible: Bool {
        alertData != nil
    }
    
    var isToastVisible: Bool {
        toastData != nil
    }

    var isLoaderVisible: Bool {
        loaderData != nil
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

    func showLoader(_ loader: LoaderModel) {
        DispatchQueue.main.async {
            self.loaderData = loader
        }
    }

    func dismissLoader() {
        DispatchQueue.main.async {
            self.loaderData = nil
        }
    }
    
    func dismissAllNotifications() {
        DispatchQueue.main.async {
            self.alertData = nil
            self.toastData = nil
            self.loaderData = nil
        }
    }
    
    func showModal(_ modal: ModalViewState) {
        DispatchQueue.main.async {
            self.modalViewData = modal
        }
    }
    
    func dismissModal() {
        DispatchQueue.main.async {
            self.modalViewData = nil
        }
    }
}

struct ModalViewModifier: ViewModifier {
    @Binding var modalViewData: ModalViewState?

    func body(content: Content) -> some View {
        ZStack {
            content
            if let modal = modalViewData {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if modal.backdropDismiss {
                            modalViewData = nil
                        }
                    }
                modal.contentView
                    .transition(.scale)
            }
        }
        .animation(.easeInOut, value: modalViewData != nil)
    }
}

struct AlertTestMainView: View {
    @StateObject private var alertService = NotificationHelperService.shared
@State private var showAlert = false
    var body: some View {
        ZStack {
//            Button("Show Testing Sheet") {
//                showAlert = true
//            }
            
            AlertTestingView()
        }
        .sheet(isPresented: $showAlert) {
                AlertTestingView()
        }
        .presentAlert(alertData: $alertService.alertData)
        .presentToast(data: $alertService.toastData)
        .presentLoader(loaderData: $alertService.loaderData)
        .presentModal(modalViewData: $alertService.modalViewData)

    }
}

struct AlertModifier: ViewModifier {
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

struct LoaderModifier: ViewModifier {
    @Binding var loaderData: LoaderModel?

    func body(content: Content) -> some View {
        ZStack {
            content
            if let loader = loaderData {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    if let text = loader.text {
                        Text(text)
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                }
                .padding(32)
                .background(Color.black.opacity(0.8))
                .cornerRadius(16)
            }
        }
        .animation(.easeInOut, value: loaderData != nil)
        .transition(.opacity)
    }
}

extension View {
    public func presentAlert(alertData: Binding<AlertModel?>) -> some View {
        self.modifier(AlertModifier(alertData: alertData))
    }
    
    public func presentToast(data: Binding<ToastModel?>) -> some View {
        self.modifier(ToastModifier(toastData: data))
    }

    public func presentLoader(loaderData: Binding<LoaderModel?>) -> some View {
        self.modifier(LoaderModifier(loaderData: loaderData))
    }
    
    public func presentModal(modalViewData: Binding<ModalViewState?>) -> some View {
        self.modifier(ModalViewModifier(modalViewData: modalViewData))
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
                duration: 20
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
    
    func showLoader() {
        NotificationHelperService.shared.showLoader(
            LoaderModel(text: "Loading...")
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.notificationHelperService.dismissLoader()
        }
    }
    
    func showModal() {
        NotificationHelperService.shared.showModal(
            ModalViewState(contentView: AnyView(ScaleHelpModal()))
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            NotificationHelperService.shared.showModal(
                ModalViewState(
                    contentView: AnyView(Text("This is another modal view")),
                               backdropDismiss: true)
            )
        }
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
            
            Button("Show Loader") {
                viewModel.showLoader()
            }
            
            Button("Show Modal") {
                viewModel.showModal()
            }
        }
    }
}

struct ScaleHelpModal: View {
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                Button(action: {
                    NotificationHelperService.shared.dismissModal()
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.gray)
                        .padding(8)
                }
            }
            .padding(.top, 4)
            .padding(.trailing, 4)

            Text("Check the back of your scale for a sticker with your four-digit model number.")
                .font(.body)
                .multilineTextAlignment(.leading)
                .foregroundColor(.black)

            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray, lineWidth: 2)
                    .frame(height: 70)
                HStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 32, height: 32)
                        .overlay(Text("G").font(.caption).foregroundColor(.gray))
                        .padding(.leading, 12)
                    Text("GREATERGOODS.COM/")
                        .font(.subheadline)
                        .foregroundColor(.black)
                    ZStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 44, height: 44)
                        Text("1234")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(.trailing, 12)
                }
            }
            .padding(.vertical, 8)

            Text("For example, if you have a 0375 Bluetooth Scale, your sticker will show the URL greatergoods.com/0375.")
                .font(.body)
                .multilineTextAlignment(.leading)
                .foregroundColor(.black)
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(radius: 24)
        .frame(maxWidth: 350)
    }
}

#Preview(body: {
    AlertTestMainView()
})

