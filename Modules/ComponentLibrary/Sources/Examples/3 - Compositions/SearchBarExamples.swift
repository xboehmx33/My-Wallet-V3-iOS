// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComponentLibrary
import SwiftUI

struct SearchBarExamples: View {
    @State var text: String = ""
    @State var isFirstResponder: Bool = false

    var body: some View {
        SearchBar(
            text: $text,
            isFirstResponder: $isFirstResponder,
            cancelButtonText: "Cancel",
            placeholder: "Search Coin"
        ) {
            print("Return tapped")
        }
        .padding(Spacing.padding())
    }
}

struct SearchBarExamples_Previews: PreviewProvider {
    static var previews: some View {
        SearchBarExamples()
    }
}
