// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComponentLibrary
import SwiftUI

struct BorderRadiiExamplesView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.padding2) {
                radiusView(
                    for: Spacing.buttonBorderRadius,
                    name: "buttonBorderRadius",
                    title: "8pt (Buttons)"
                )
                radiusView(
                    for: Spacing.containerBorderRadius,
                    name: "containerBorderRadius",
                    title: "16pt (Containers)"
                )
                radiusView(
                    for: Spacing.roundedBorderRadius(for: 188),
                    name: "roundedBorderRadius(for:)",
                    title: "100% (Alerts)"
                )
            }
            .padding(Spacing.padding())
        }
    }

    @ViewBuilder func radiusView(for radius: CGFloat, name: String, title: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: radius)
                .fill(Color.semantic.background)

            RoundedRectangle(cornerRadius: radius)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5, 3]))
                .foregroundColor(.red)

            VStack(spacing: Spacing.padding1) {
                Text(name)
                    .typography(.title3)

                Text(title)
                    .typography(.body1)
            }
            .foregroundColor(.semantic.title)
        }
        .frame(height: 188)
    }
}

struct BorderRadiiExamplesView_Previews: PreviewProvider {
    static var previews: some View {
        BorderRadiiExamplesView()
    }
}
