//
//  ReactiveFormTestingView.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 06/06/25.
//

import SwiftUI
import ReactiveForm



#Preview {
    ReactiveFormTestingView1()
}
class SettingsForm: ObservableForm {
  var name = FormControl("", validators: [.required], type: .manually)

  var email = FormControl("", validators: [.email], type: .manually)
}

struct ReactiveFormTestingView1: View {
  @StateObject var form = SettingsForm()

  var body: some View {
    Form {
      TextField("Name", text: $form.name.value)
      if form.name.isDirty && form.name.errors[.required] {
        Text("Please fill a name.")
          .foregroundColor(.red)
      }
      TextField("Email", text: $form.email.value)
      if form.email.isDirty && form.email.errors[.email] {
        Text("Please fill a valid email.")
          .foregroundColor(.red)
      }
      Button(action: {}) {
        Text("Submit")
      }
      .disabled(form.isInvalid)
    }
  }
}
