// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComponentLibrary
import SwiftUI
import UIKit

struct InputExamples: View {
    @State var firstResponder: Field? = .email

    @State var text: String = ""

    @State var password: String = ""
    @State var hidePassword: Bool = true

    @State var number: String = ""

    enum Field {
        case email
        case password
        case number
    }

    var showPasswordError: Bool {
        !password.isEmpty && password.count < 5
    }

    var body: some View {
        VStack {
            // Text
            Input(
                text: $text,
                isFirstResponder: firstResponderBinding(for: .email),
                subTextStyle: .default,
                placeholder: "Email Address",
                prefix: nil,
                state: .default,
                configuration: { textField in
                    textField.keyboardType = .emailAddress
                    textField.textContentType = .emailAddress
                    textField.returnKeyType = .next
                },
                onReturnTapped: {
                    firstResponder = .password
                }
            )

            // Password
            Input(
                text: $password,
                isFirstResponder: firstResponderBinding(for: .password),
                subText: showPasswordError ? "Password too short" : nil,
                subTextStyle: showPasswordError ? .error : .default,
                placeholder: "Password",
                state: showPasswordError ? .error : .default,
                configuration: { textField in
                    textField.isSecureTextEntry = hidePassword
                    textField.textContentType = .password
                    textField.returnKeyType = .next
                },
                trailing: {
                    if hidePassword {
                        IconButton(icon: .visibilityOn) {
                            hidePassword = false
                        }
                    } else {
                        IconButton(icon: .visibilityOff) {
                            hidePassword = true
                        }
                    }
                },
                onReturnTapped: {
                    firstResponder = .number
                }
            )

            // Number
            Input(
                text: $number,
                isFirstResponder: firstResponderBinding(for: .number),
                label: "Purchase amount",
                placeholder: "0",
                prefix: "USD",
                configuration: { textField in
                    textField.keyboardType = .decimalPad
                    textField.returnKeyType = .done
                }
            )

            Spacer()
        }
        .padding()
    }

    func firstResponderBinding(for field: Field) -> Binding<Bool> {
        Binding(
            get: { firstResponder == field },
            set: { newValue in
                if newValue {
                    firstResponder = field
                } else if firstResponder == field {
                    firstResponder = nil
                }
            }
        )
    }
}

struct InputExamples_Previews: PreviewProvider {
    static var previews: some View {
        InputExamples()
    }
}
