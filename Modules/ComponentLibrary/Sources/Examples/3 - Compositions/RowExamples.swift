// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComponentLibrary
import SwiftUI

struct RowExamplesView: View {

    private let data: NavigationLinkProviderList = [
        "Rows": [
            NavigationLinkProvider(view: PrimaryRowExamplesView(), title: "PrimaryRow"),
            NavigationLinkProvider(view: BalanceRowExamplesView(), title: "BalanceRow")
        ]
    ]

    var body: some View {
        NavigationLinkProviderView(data: data)
    }
}

struct RowExamplesView_Previews: PreviewProvider {
    static var previews: some View {
        PrimaryNavigationView {
            RowExamplesView()
        }
    }
}
