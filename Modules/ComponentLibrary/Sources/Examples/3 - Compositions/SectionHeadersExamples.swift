// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComponentLibrary
import SwiftUI

struct SectionHeadersExamples: View {

    private let data: NavigationLinkProviderList = [
        "Section Headers": [
            NavigationLinkProvider(view: SectionHeaderExamplesView(), title: "SectionHeader")
        ]
    ]

    var body: some View {
        NavigationLinkProviderView(data: data)
    }
}

struct SectionHeadersExamples_Previews: PreviewProvider {
    static var previews: some View {
        PrimaryNavigationView {
            SectionHeadersExamples()
        }
    }
}
