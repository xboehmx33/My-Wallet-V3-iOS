// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import SwiftUI

/// SectionHeader from the Figma Component Library.
///
/// # Usage:
///
/// Can be a Section Header inside a List, VStack or other.
/// ```
/// List {
///     Section(header: SectionHeader(title: "Wallets & Accounts"))  {
///         ...
///     }
/// }
/// ```
///
/// - Version: 1.0.1
///
/// # Figma
///
///  [Section Header](https://www.figma.com/file/nlSbdUyIxB64qgypxJkm74/03---iOS-%7C-Shared?node-id=209%3A11327)
public struct SectionHeader<Trailing: View>: View {

    private let title: String
    private let variant: SectionHeaderVariant
    private let trailing: Trailing

    /// Initialize a section header with a trailing view
    /// - Parameters:
    ///   - title: Leading title text
    ///   - variant: `.regular` (default) for wallet, `.large` for exchange.
    ///   - trailing: Generic view displayed trailing in the section header. (for exchange)
    public init(
        title: String,
        variant: SectionHeaderVariant = .regular,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.title = title
        self.variant = variant
        self.trailing = trailing()
    }

    public var body: some View {
        HStack {
            Text(title)
                .typography(variant.typography)
                .foregroundColor(variant.fontColor)
            Spacer()
            trailing
                .frame(maxHeight: 24)
        }
        .padding(variant.padding)
        .background(variant.backgroundColor)
        .listRowInsets(
            EdgeInsets(
                top: 0,
                leading: 0,
                bottom: 0,
                trailing: 0
            )
        )
    }
}

extension SectionHeader where Trailing == EmptyView {

    /// Initialize a section header without a trailing view (for wallet)
    /// - Parameters:
    ///   - title: Leading title text
    ///   - variant: `.regular` (default) for wallet, `.large` for exchange.
    public init(
        title: String,
        variant: SectionHeaderVariant = .regular
    ) {
        self.init(
            title: title,
            variant: variant
        ) {
            EmptyView()
        }
    }
}

/// Variant types for `SectionHeader`
public struct SectionHeaderVariant {
    let typography: Typography
    let fontColor: Color
    let backgroundColor: Color
    let padding: EdgeInsets

    /// Regular section header variant, used for Wallet app.
    public static let regular = Self(
        typography: .caption2,
        fontColor: .semantic.title,
        backgroundColor: .semantic.light,
        padding: EdgeInsets(
            top: Spacing.baseline,
            leading: Spacing.padding3,
            bottom: Spacing.baseline,
            trailing: Spacing.padding3
        )
    )

    /// Large section header variant, used for exchange app.
    public static let large = Self(
        typography: .paragraph2,
        fontColor: Color(
            light: .palette.grey600,
            dark: .palette.dark200
        ),
        backgroundColor: .semantic.background,
        padding: EdgeInsets(
            top: 14,
            leading: 16,
            bottom: 14,
            trailing: 12
        )
    )
}

struct SectionHeader_Previews: PreviewProvider {

    static var previews: some View {
        SectionHeader(title: "Regular")
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Regular")

        SectionHeader(title: "Large", variant: .large)
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Large")

        SectionHeader(title: "Large with Trailing", variant: .large) {
            IconButton(icon: .qrCode) {}
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Large with Trailing")
    }
}
