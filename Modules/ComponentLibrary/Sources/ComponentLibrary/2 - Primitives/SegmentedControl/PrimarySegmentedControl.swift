// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import SwiftUI

/// PrimarySegmentedControl from the Figma Component Library.
///
///
/// # Usage:
///
/// The PrimarySegmentedControl can be initialized with any number of items,
/// and a selection parameter, which indicates the initial selection state.
/// Every item can be initialized with a title and a one of its two possible variants. Plus an identifier.
///
/// `PrimarySegmentedControl(
///     items: [
///         PrimarySegmentedControlItem(title: "Live", variant: .dot, identifier: "live"),
///         PrimarySegmentedControlItem(title: "1D", identifier: "1d"),
///         PrimarySegmentedControlItem(title: "1W", identifier: "1w"),
///         PrimarySegmentedControlItem(title: "1M", identifier: "1m"),
///         PrimarySegmentedControlItem(title: "1Y", identifier: "1y"),
///         PrimarySegmentedControlItem(title: "All", identifier: "all")
///     ],
///     selection: $selected
/// )`
///
/// - Version: 1.0.1
///
/// # Figma
///
///  [Controls](https://www.figma.com/file/nlSbdUyIxB64qgypxJkm74/03---iOS-%7C-Shared?node-id=6%3A544)
public struct PrimarySegmentedControl<Selection: Hashable>: View {

    private var items: [Item]

    @Binding private var selection: Selection

    /// Create a PrimarySegmentedControl view with any number of items and a selection state.
    /// - Parameter items: Items who represents the buttons inside the segmented control
    /// - Parameter selection: Binding for `selection` from `items` for the currently selected item.
    public init(
        items: [Item],
        selection: Binding<Selection>
    ) {
        self.items = items
        _selection = selection
    }

    public var body: some View {
        HStack(spacing: 8) {
            ForEach(items) { item in
                Button(
                    title: item.title,
                    variant: item.variant,
                    isOn: Binding(
                        get: {
                            selection == item.identifier
                        },
                        set: { _ in
                            selection = item.identifier
                        }
                    )
                )
                .anchorPreference(key: ButtonPreferenceKey.self, value: .bounds, transform: { anchor in
                    [item.identifier: anchor]
                })
            }
        }
        .fixedSize()
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .backgroundPreferenceValue(ButtonPreferenceKey.self) { value in
            GeometryReader { proxy in
                if let anchor = value[selection] {
                    movingRectangle(proxy: proxy, anchor: anchor)
                }
            }
        }
        .background(Color.semantic.background)
    }

    @ViewBuilder private func movingRectangle(proxy: GeometryProxy, anchor: Anchor<CGRect>) -> some View {
        RoundedRectangle(cornerRadius: 48)
            .fill(
                Color(
                    light: .palette.white,
                    dark: .palette.dark800
                )
            )
            .shadow(
                color: Color(
                    light: .palette.black.opacity(0.06),
                    dark: .palette.black.opacity(0.12)
                ),
                radius: 1,
                x: 0,
                y: 3
            )
            .shadow(
                color: Color(
                    light: .palette.black.opacity(0.15),
                    dark: .palette.black.opacity(0.12)
                ),
                radius: 8,
                x: 0,
                y: 3
            )
            .frame(
                width: proxy[anchor].width,
                height: proxy[anchor].height
            )
            .offset(
                x: proxy[anchor].minX,
                y: proxy[anchor].minY
            )
            .animation(.interactiveSpring())
    }
}

extension PrimarySegmentedControl {

    public struct Item: Identifiable {

        let title: String
        let variant: Variant
        let identifier: Selection

        public var id: Selection { identifier }

        /// Create an Item which is the element to pass into the PrimarySegmentedControl,
        /// as a representation for the buttons to be shown on the control.
        /// The parameters defined on the items are the data used to display a button.
        /// - Parameter title: title of the item, will be the title of the button
        /// - Parameter variant: style variant to use on the button
        /// - Parameter identifier: unique identifier which is used to determine which button is on the selected state. The identifier must to be set in order for the control to work with unique elements.
        public init(
            title: String,
            variant: Variant = .standard,
            identifier: Selection
        ) {
            self.title = title
            self.variant = variant
            self.identifier = identifier
        }

        /// Style variant for the button
        public enum Variant {
            case standard
            case dot
        }
    }
}

private struct ButtonPreferenceKey: PreferenceKey {
    static var defaultValue: [AnyHashable: Anchor<CGRect>] = [:]

    static func reduce(
        value: inout [AnyHashable: Anchor<CGRect>],
        nextValue: () -> [AnyHashable: Anchor<CGRect>]
    ) {
        value.merge(
            nextValue(),
            uniquingKeysWith: { _, next in
                next
            }
        )
    }
}

struct PrimarySegmentedControl_Previews: PreviewProvider {

    static var previews: some View {
        Group {
            PreviewController(
                items: [
                    PrimarySegmentedControl.Item(title: "Live", variant: .dot, identifier: "live"),
                    PrimarySegmentedControl.Item(title: "1D", identifier: "1d"),
                    PrimarySegmentedControl.Item(title: "1W", identifier: "1w"),
                    PrimarySegmentedControl.Item(title: "1M", identifier: "1m"),
                    PrimarySegmentedControl.Item(title: "1Y", identifier: "1y"),
                    PrimarySegmentedControl.Item(title: "All", identifier: "all")
                ],
                selection: "live"
            )
            .previewLayout(.sizeThatFits)
            .previewDisplayName("PrimarySegmentedControl")

            PreviewController(
                items: [
                    PrimarySegmentedControl.Item(title: "Live", variant: .dot, identifier: "live"),
                    PrimarySegmentedControl.Item(title: "1D", identifier: "1d"),
                    PrimarySegmentedControl.Item(title: "1W", identifier: "1w"),
                    PrimarySegmentedControl.Item(title: "1M", identifier: "1m"),
                    PrimarySegmentedControl.Item(title: "1Y", identifier: "1y"),
                    PrimarySegmentedControl.Item(title: "All", identifier: "all")
                ],
                selection: "1m"
            )
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Initial Selection")

            PreviewController(
                items: [
                    PrimarySegmentedControl.Item(title: "First", identifier: "first"),
                    PrimarySegmentedControl.Item(title: "Second", identifier: "second"),
                    PrimarySegmentedControl.Item(title: "Third", identifier: "third")
                ],
                selection: "first"
            )
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Short")

            PreviewController(
                items: [
                    PrimarySegmentedControl.Item(title: "Today", variant: .dot, identifier: "today"),
                    PrimarySegmentedControl.Item(title: "Tomorrow", identifier: "tomorrow"),
                    PrimarySegmentedControl.Item(title: "Now", identifier: "now"),
                    PrimarySegmentedControl.Item(title: "Ready", variant: .dot, identifier: "ready")
                ],
                selection: "ready"
            )
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Mixed")
        }
        .padding()
    }

    struct PreviewController<Selection: Hashable>: View {
        let items: [PrimarySegmentedControl<Selection>.Item]
        @State var selection: Selection

        init(
            items: [PrimarySegmentedControl<Selection>.Item],
            selection: Selection
        ) {
            self.items = items
            _selection = State(initialValue: selection)
        }

        var body: some View {
            PrimarySegmentedControl(
                items: items,
                selection: $selection
            )
        }
    }
}
