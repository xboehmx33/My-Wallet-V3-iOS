// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComponentLibrary
import SwiftUI

struct LargeSegmentedControlExamples: View {
    @State var firstSelection: AnyHashable = "leading"
    @State var secondSelection: AnyHashable = "trailing"
    @State var thirdSelection: AnyHashable = "first"

    enum Option: String {
        case one
        case two
    }

    @State var option: Option = .two

    var body: some View {
        VStack(spacing: Spacing.padding1) {
            LargeSegmentedControl(
                items: [
                    LargeSegmentedControl.Item(title: "Leading", identifier: "leading"),
                    LargeSegmentedControl.Item(title: "Trailing", identifier: "trailing")
                ],
                selection: $firstSelection
            )

            LargeSegmentedControl(
                items: [
                    LargeSegmentedControl.Item(title: "Leading", identifier: "leading"),
                    LargeSegmentedControl.Item(title: "Trailing", identifier: "trailing")
                ],
                selection: $secondSelection
            )

            LargeSegmentedControl(
                items: [
                    LargeSegmentedControl.Item(title: Option.one.rawValue, identifier: Option.one),
                    LargeSegmentedControl.Item(title: Option.two.rawValue, identifier: Option.two)
                ],
                selection: $option
            )

            LargeSegmentedControl(
                items: [
                    LargeSegmentedControl.Item(title: "First", identifier: "first"),
                    LargeSegmentedControl.Item(title: "Second", identifier: "second"),
                    LargeSegmentedControl.Item(title: "Third", identifier: "third"),
                    LargeSegmentedControl.Item(title: "Fourth", identifier: "fourth")
                ],
                selection: $thirdSelection
            )
        }
        .padding(Spacing.padding())
    }
}

struct LargeSegmentedControlExamples_Previews: PreviewProvider {
    static var previews: some View {
        LargeSegmentedControlExamples()
    }
}
