// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComponentLibrary
import SwiftUI

struct PaddingExamplesView: View {
    var body: some View {
        ScrollView {
            VStack {
                paddingView(for: Spacing.padding1, title: "padding1")
                paddingView(for: Spacing.padding2, title: "padding2")
                paddingView(for: Spacing.padding3, title: "padding3")
                paddingView(for: Spacing.padding4, title: "padding4")
                paddingView(for: Spacing.padding5, title: "padding5")
                paddingView(for: Spacing.padding6, title: "padding6")
            }
        }
    }

    @ViewBuilder func paddingView(for padding: CGFloat, title: String) -> some View {
        ZStack {
            Rectangle()
                .foregroundColor(.semantic.background)
                .border(Color.red, width: 0.5)
                .padding(padding)

            VStack(spacing: Spacing.padding1) {
                Text(title)
                    .typography(.title3)
                Text("\(padding)")
                    .typography(.body1)
            }
            .foregroundColor(.semantic.title)
        }
        .frame(height: 188)
        .background(Color.gray.opacity(0.1))
    }
}

struct PaddingExamplesView_Previews: PreviewProvider {
    static var previews: some View {
        PaddingExamplesView()
    }
}
