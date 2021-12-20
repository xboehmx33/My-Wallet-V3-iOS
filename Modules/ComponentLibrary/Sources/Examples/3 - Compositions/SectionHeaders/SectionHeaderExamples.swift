// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComponentLibrary
import SwiftUI

struct SectionHeaderExamplesView: View {
    var body: some View {
        VStack {
            SectionHeader(title: "Regular (wallet)")

            SectionHeader(title: "Large (exchange)", variant: .large)

            SectionHeader(
                title: "Large with Icon (exchange)",
                variant: .large
            ) {
                IconButton(icon: .qrCode) {}
            }
        }
    }
}

struct SectionHeaderExamplesView_Previews: PreviewProvider {
    static var previews: some View {
        SectionHeaderExamplesView()
    }
}
