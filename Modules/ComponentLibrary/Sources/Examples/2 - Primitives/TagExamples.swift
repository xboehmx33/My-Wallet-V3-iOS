// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComponentLibrary
import SwiftUI

struct TagExamples: View {
    var body: some View {
        VStack(spacing: Spacing.baseline) {
            Tag(text: "default") // variant: .default
            Tag(text: "default", size: .large) // variant: .default

            Tag(text: "infoAlt", variant: .infoAlt)
            Tag(text: "infoAlt", variant: .infoAlt, size: .large)

            Tag(text: "success", variant: .success)
            Tag(text: "success", variant: .success, size: .large)

            Tag(text: "warning", variant: .warning)
            Tag(text: "warning", variant: .warning, size: .large)

            Tag(text: "error", variant: .error)
            Tag(text: "error", variant: .error, size: .large)
        }
        .padding(Spacing.padding())
    }
}

struct TagExamples_Previews: PreviewProvider {
    static var previews: some View {
        TagExamples()
    }
}
