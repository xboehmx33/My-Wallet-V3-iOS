// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComponentLibrary
import SwiftUI

struct AlertToastExamples: View {

    var body: some View {
        VStack(spacing: 30) {
            VStack {
                AlertToast(text: "Default", variant: .default)
                AlertToast(text: "Default", variant: .default, icon: .refresh)
            }
            VStack {
                AlertToast(text: "Success", variant: .success)
                AlertToast(text: "Success", variant: .success, icon: .checkCircle)
            }
            VStack {
                AlertToast(text: "Warning", variant: .warning)
                AlertToast(text: "Warning", variant: .warning, icon: .alert)
            }
            VStack {
                AlertToast(text: "Error", variant: .error)
                AlertToast(text: "Error", variant: .error, icon: .error)
            }
        }
        .padding()
    }
}

struct AlertToastExamples_Previews: PreviewProvider {
    static var previews: some View {
        AlertToastExamples()
    }
}
