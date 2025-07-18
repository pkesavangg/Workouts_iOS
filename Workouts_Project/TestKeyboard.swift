//
//  TestKeyboard.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 05/07/25.
//


import SwiftUI

struct TestKeyboard: View {
    @State var str: String = ""
    @State var num: Float = 1.2

    @FocusState private var focusedField: Field?
    private enum Field: Int, CaseIterable {
        case amount
        case str
    }

    var body: some View {
        VStack {
            Spacer()
            
            // I'm not adding .toolbar here...
            TextField("A text field here", text: $str)
                .focused($focusedField, equals: .str)

            // I'm only adding .toolbar here, but it still shows for the one above..
            TextField("", value: $num, formatter: FloatNumberFormatter())
                .keyboardType(.decimalPad)
                .focused($focusedField, equals: .amount)
                .toolbar {
                    ToolbarItem(placement: .keyboard) {
                        HStack {
                            Spacer()
                            Button("Done") {
                                focusedField = nil
                            }
                        }
                    }
                }

            Spacer()
        }
    }
}

class FloatNumberFormatter: NumberFormatter, @unchecked Sendable {
    override init() {
        super.init()
        
        self.numberStyle = .currency        
        self.currencySymbol = "€"
        self.minimumFractionDigits = 2
        self.maximumFractionDigits = 2
        self.locale = Locale.current
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

// So you can preview it quickly
struct TestKeyboard_Previews: PreviewProvider {
    static var previews: some View {
        TestKeyboard()
    }
}
