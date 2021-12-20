// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComponentLibrary
import SwiftUI

struct SecondaryButtonExamplesView: View {

    var body: some View {
        VStack(spacing: Spacing.padding1) {
            SecondaryButton(title: "Enabled", action: {})

            SecondaryButton(title: "With Icon", leadingView: { Icon.placeholder }, action: {})

            SecondaryButton(title: "Disabled", action: {})
                .disabled(true)

            SecondaryButton(title: "Loading", isLoading: true, action: {})
        }
        .padding(Spacing.padding())
    }
}

struct SecondaryButtonExamplesView_Previews: PreviewProvider {
    static var previews: some View {
        SecondaryButtonExamplesView()
    }
}
