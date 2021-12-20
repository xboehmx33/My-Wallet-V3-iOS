// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComponentLibrary
import SwiftUI

struct CheckboxExamples: View {
    @State var isOn: Bool = true

    var body: some View {
        VStack(spacing: Spacing.baseline) {
            Checkbox(isOn: $isOn)

            Checkbox(isOn: $isOn, variant: .error)
        }
        .padding(Spacing.padding())
    }
}

struct CheckboxExamples_Previews: PreviewProvider {
    static var previews: some View {
        CheckboxExamples()
    }
}
