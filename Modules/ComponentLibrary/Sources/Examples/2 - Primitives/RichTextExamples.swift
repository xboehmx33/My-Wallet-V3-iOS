// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComponentLibrary
import SwiftUI

struct RichTextExamples: View {
    @State var text: String = """
    ## Markdown
    The *quick* brown _fox_ **jumps** over the ~lazy~ dog.

    [Links](https://blockchain.com) get styling, but no tap action.
    """

    var body: some View {
        VStack(spacing: 0) {
            SectionHeader(title: "Rendered")

            ScrollView {
                HStack {
                    RichText(text) // or `Text(rich:)`
                        .typography(.body1)
                        .padding(Spacing.padding())

                    Spacer(minLength: 0)
                }
            }

            SectionHeader(title: "Edit Below")

            TextEditor(text: $text)
                .padding(.vertical)
        }
    }
}

struct RichTextExamples_Previews: PreviewProvider {
    static var previews: some View {
        RichTextExamples()
    }
}
