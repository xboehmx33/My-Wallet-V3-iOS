// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComponentLibrary
import SwiftUI

struct PrimaryButtonExamplesView: View {

    var body: some View {
        VStack(spacing: Spacing.padding1) {
            PrimaryButton(title: "Enabled", action: { print("foo") })

            PrimaryButton(title: "With Icon", leadingView: { Icon.placeholder }, action: {})

            PrimaryButton(title: "Disabled", action: {})
                .disabled(true)

            PrimaryButton(title: "Loading", isLoading: true, action: {})
        }
        .padding(Spacing.padding())
    }
}

struct PrimaryButtonExamplesView_Previews: PreviewProvider {
    static var previews: some View {
        PrimaryButtonExamplesView()
    }
}
