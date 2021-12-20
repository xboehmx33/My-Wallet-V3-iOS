// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComponentLibrary
import SwiftUI

struct SegmentedControlExamples: View {

    private let data: NavigationLinkProviderList = [
        "Segmented Controls": [
            NavigationLinkProvider(view: PrimarySegmentedControlExamples(), title: "PrimarySegmentedControl"),
            NavigationLinkProvider(view: LargeSegmentedControlExamples(), title: "LargeSegmentedControl")
        ]
    ]

    var body: some View {
        NavigationLinkProviderView(data: data)
    }
}

struct SegmentedControlExamples_Previews: PreviewProvider {
    static var previews: some View {
        PrimaryNavigationView {
            SegmentedControlExamples()
        }
    }
}
