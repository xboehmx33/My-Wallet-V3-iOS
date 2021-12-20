// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import SwiftUI

extension PrimarySegmentedControl {

    struct Button: View {

        private let title: String
        private let variant: PrimarySegmentedControl.Item.Variant

        @Binding private var isOn: Bool

        init(
            title: String,
            variant: PrimarySegmentedControl.Item.Variant = .standard,
            isOn: Binding<Bool>
        ) {
            self.title = title
            self.variant = variant
            _isOn = isOn
        }

        var body: some View {
            HStack(alignment: .bottom, spacing: 6) {
                if variant == .dot {
                    Circle()
                        .fill(
                            isOn ? .semantic.success : Color(
                                light: .palette.grey400,
                                dark: .palette.grey400
                            )
                        )
                        .frame(width: 5, height: 5)
                        .padding(.bottom, 5)
                }
                Text(title)
                    .typography(.paragraph2)
            }
            .fixedSize()
            .frame(maxWidth: .infinity)
            .onTapGesture {
                isOn.toggle()
            }
            .foregroundColor(
                isOn ? .semantic.primary : Color(
                    light: .palette.grey400,
                    dark: .palette.grey400
                )
            )
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
        }
    }
}

struct PrimarySegmentedControlButton_Previews: PreviewProvider {

    static var previews: some View {
        Group {
            PreviewController(title: "1D", variant: .standard, isOn: true)
                .previewLayout(.sizeThatFits)
                .previewDisplayName("Selected")

            PreviewController(title: "1D", variant: .standard, isOn: false)
                .previewLayout(.sizeThatFits)
                .previewDisplayName("Unselected")

            PreviewController(title: "Live", variant: .dot, isOn: true)
                .previewLayout(.sizeThatFits)
                .previewDisplayName("Dot variant Selected")

            PreviewController(title: "Live", variant: .dot, isOn: false)
                .previewLayout(.sizeThatFits)
                .previewDisplayName("Dot variant Unselected")
        }
        .padding()
    }

    struct PreviewController: View {
        let title: String
        let variant: PrimarySegmentedControl<AnyHashable>.Item.Variant
        @State var isOn: Bool

        var body: some View {
            PrimarySegmentedControl<AnyHashable>.Button(title: title, variant: variant, isOn: $isOn)
        }
    }
}
