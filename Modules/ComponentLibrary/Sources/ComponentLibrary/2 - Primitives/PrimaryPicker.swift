// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import SwiftUI

/// A vertical list of buttons used for displaying pickers.
///
/// Examples include date or country pickers contained in a grouped form.
///
/// Optionally contains trailing view, and can display inline pickers.
///
/// # Figma
///
/// [Picker](https://www.figma.com/file/nlSbdUyIxB64qgypxJkm74/03---iOS-%7C-Shared?node-id=721%3A7394)
public struct PrimaryPicker<Selection: Hashable>: View {
    @Binding private var selection: Selection?
    private let rows: [Row]

    /// Create a set of picker buttons.
    ///
    /// - Parameters:
    ///   - selection: Binding for `selection` from `rows` for the currently selected row.
    ///   - rows: Items representing the rows within the picker. see `PrimaryPicker.Row`
    public init(selection: Binding<Selection?>, rows: [Row]) {
        _selection = selection
        self.rows = rows
    }

    public var body: some View {
        VStack(spacing: 0) {
            ForEach(rows.indices) { index in
                rows[index].builder($selection)
                    .background(
                        RowBackground(position: position(for: index))
                    )
            }
        }
    }

    private func position(for index: Int) -> Row.Position {
        guard rows.count > 1 else {
            return .single
        }

        switch index {
        case 0:
            return .top
        case rows.count - 1:
            return .bottom
        default:
            return .middle
        }
    }
}

extension PrimaryPicker {

    /// A row item within a `PrimaryPicker`
    public struct Row {
        fileprivate let builder: (Binding<Selection?>) -> AnyView

        /// Create a row with trailing view & picker.
        ///
        /// - Parameters:
        ///   - title: Leading title displayed in the row
        ///   - identifier: ID for determining `selection`
        ///   - trailing: Trailing view displayed in the row. Commonly contains `Tag`.
        ///   - picker: Picker displayed below the row when selected. eg `DatePicker`
        /// - Returns: A row for use in `PrimaryPicker`
        public static func row<Trailing: View, Picker: View>(
            title: String,
            identifier: Selection,
            @ViewBuilder trailing: @escaping () -> Trailing,
            @ViewBuilder picker: @escaping () -> Picker
        ) -> Row {
            Row { selection in
                PickerRow(
                    title: title,
                    isActive: Binding(
                        get: {
                            selection.wrappedValue == identifier
                        },
                        set: { newValue in
                            if newValue {
                                selection.wrappedValue = identifier
                            } else {
                                selection.wrappedValue = nil
                            }
                        }
                    ),
                    picker: picker(),
                    trailing: trailing
                )
            }
        }

        /// Create a row with picker.
        ///
        /// - Parameters:
        ///   - title: Leading title displayed in the row
        ///   - identifier: ID for determining `selection`
        ///   - picker: Picker displayed below the row when selected. eg `DatePicker`
        /// - Returns: A row for use in `PrimaryPicker`
        public static func row<Picker: View>(
            title: String,
            identifier: Selection,
            @ViewBuilder picker: @escaping () -> Picker
        ) -> Row {
            row(
                title: title,
                identifier: identifier,
                trailing: EmptyView.init,
                picker: picker
            )
        }

        /// Create a tappable row with trailing view.
        ///
        /// Used for displaying non-inline picker such as an alert or bottom sheet.
        ///
        /// - Parameters:
        ///   - title: Leading title displayed in the row
        ///   - identifier: ID for determining `selection`
        ///   - trailing: Trailing view displayed in the row. Commonly contains `Tag`.
        /// - Returns: A row for use in `PrimaryPicker`
        public static func row<Trailing: View>(
            title: String,
            identifier: Selection,
            @ViewBuilder trailing: @escaping () -> Trailing
        ) -> Row {
            row(
                title: title,
                identifier: identifier,
                trailing: trailing,
                picker: EmptyView.init
            )
        }

        /// Create a tappable row with only a title.
        ///
        /// Used for displaying non-inline picker such as an alert or bottom sheet.
        ///
        /// - Parameters:
        ///   - title: Leading title displayed in the row
        ///   - identifier: ID for determining `selection`
        /// - Returns: A row for use in `PrimaryPicker`
        public static func row(
            title: String,
            identifier: Selection
        ) -> Row {
            row(
                title: title,
                identifier: identifier,
                trailing: EmptyView.init,
                picker: EmptyView.init
            )
        }

        private init<T: View>(@ViewBuilder _ view: @escaping (Binding<Selection?>) -> T) {
            builder = { AnyView(view($0)) }
        }
    }
}

// MARK: - Private

extension PrimaryPicker {

    /// Shaped background with optional rounded corners.
    private struct RowBackground: View {
        let position: Row.Position

        private var corners: UIRectCorner {
            switch position {
            case .single:
                return .allCorners
            case .top:
                return [.topLeft, .topRight]
            case .bottom:
                return [.bottomLeft, .bottomRight]
            case .middle:
                return []
            }
        }

        var body: some View {
            ZStack {
                if corners.isEmpty {
                    Rectangle()
                        .fill(Color.semantic.background)

                    Rectangle()
                        .stroke(Color.semantic.medium, lineWidth: 1)
                } else {
                    RowShape(corners: corners)
                        .fill(Color.semantic.background)

                    RowShape(corners: corners)
                        .stroke(Color.semantic.medium, lineWidth: 1)
                }
            }
        }
    }
}

/// Shape object for `PrimaryPicker.RowBackground`
///
/// Nesting this type causes previews to fail, so it is left at top level.
private struct RowShape: Shape {
    let corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(
                width: Spacing.buttonBorderRadius,
                height: Spacing.buttonBorderRadius
            )
        )
        return Path(path.cgPath)
    }
}

extension PrimaryPicker.Row {

    /// Position of row amoung others for determining shaped background
    fileprivate enum Position {
        case single
        case top
        case middle
        case bottom
    }

    /// Generic view used to display an individual picker row
    private struct PickerRow<Trailing: View, Picker: View>: View {
        let title: String
        @Binding var isActive: Bool
        let picker: Picker
        @ViewBuilder let trailing: () -> Trailing

        var body: some View {
            VStack(spacing: 0) {
                Button(
                    action: {
                        withAnimation(.easeInOut) {
                            isActive.toggle()
                        }
                    },
                    label: {
                        HStack(spacing: 0) {
                            Text(title)
                                .typography(.body1)
                                .foregroundColor(.semantic.title)
                                .padding(.vertical, 12)

                            Spacer()

                            trailing()
                        }
                    }
                )
                .padding(.horizontal, 16)

                if isActive, !(picker is EmptyView) {
                    Rectangle()
                        .fill(Color.semantic.medium)
                        .frame(height: 1)

                    picker
                        .padding(.horizontal, 16)
                }
            }
            .clipShape(Rectangle())
        }
    }
}

// MARK: - Previews

struct PrimaryPicker_Previews: PreviewProvider {
    static var previews: some View {
        PrimaryPicker(
            selection: .constant(nil),
            rows: [
                .row(title: "One", identifier: "one", trailing: { Tag(text: "Trailing") }),
                .row(title: "Two", identifier: "two"),
                .row(title: "Three", identifier: "three")
            ]
        )
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Multi")

        PrimaryPicker(
            selection: .constant(nil),
            rows: [
                .row(title: "One", identifier: "one"),
                .row(title: "Two", identifier: "two")
            ]
        )
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Two")

        PrimaryPicker(
            selection: .constant(nil),
            rows: [
                .row(title: "One", identifier: "one")
            ]
        )
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Single")

        PrimaryPicker(
            selection: .constant("one"),
            rows: [
                .row(title: "One", identifier: "one", picker: { Text("Picker") })
            ]
        )
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Single, selected with picker")
    }
}
