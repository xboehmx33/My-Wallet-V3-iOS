// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import SwiftUI

/// BalanceRow from the Figma Component Library.
///
///
/// # Usage:
///
/// The actual final layout of this cell depends on the parameters assigned on initialization.
/// LeadingSubtitle, TrailingDescriptionColor and graph are optional parameters
/// ```
/// BalanceRow(
///     leadingTitle: "Trading Account",
///     leadingDescription: "Bitcoin",
///     trailingTitle: "$7,926.43",
///     trailingDescription: "0.00039387 BTC",
///     tags: [
///         Tag(text: "No Fees", variant: .success),
///         Tag(text: "Faster", variant: .success),
///         Tag(text: "Warning Alert", variant: .warning)
///     ]
/// ) {
///     Icon.trade
///         .fixedSize()
///         .accentColor(.semantic.primary)
/// }
///
/// ```
///
/// - Version: 1.0.1
///
/// # Figma
///
///  [Table Rows](https://www.figma.com/file/nlSbdUyIxB64qgypxJkm74/03---iOS-%7C-Shared?node-id=209%3A11163)

public struct BalanceRow<Leading: View, Graph: View>: View {

    private let leading: Leading
    private let leadingTitle: String
    private let leadingSubtitle: String?
    private let leadingDescription: String
    private let graph: Graph?
    private let trailingTitle: String
    private let trailingDescription: String
    private let trailingDescriptionColor: Color
    private let tags: [Tag]
    private let mainContentSpacing: CGFloat = 6

    /// Create a Balance Row with the given data.
    ///
    /// LeadingSubtitle, TrailingDescriptionColor and graph are optional parameters and the row will form itself depending on the given data.
    /// The position of some views inside the row will vary depending on the data present.
    ///
    /// - Parameters:
    ///   - leadingTitle: Title on the leading side of the row
    ///   - leadingSubtitle: Optional subtitle on the leading side of the row
    ///   - leadingDescription: Description string on the leading side of the row
    ///   - trailingTitle: Title on the trailing side of the row
    ///   - trailingDescription: Description string on the trailing side of the row view
    ///   - trailingDescriptionColor: Optional color for the trailingDescription text
    ///   - tags: Optional array of tags object. They show up on the bottom part of the main vertical content view, and align themself horizontally
    ///   - leading: View on the leading side of the row.
    ///   - graph: View on the trailing side of the row.
    public init(
        leadingTitle: String,
        leadingSubtitle: String? = nil,
        leadingDescription: String,
        trailingTitle: String,
        trailingDescription: String,
        trailingDescriptionColor: Color? = nil,
        tags: [Tag] = [],
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder graph: () -> Graph
    ) {
        self.leadingTitle = leadingTitle
        self.leadingSubtitle = leadingSubtitle
        self.leadingDescription = leadingDescription
        self.trailingTitle = trailingTitle
        self.trailingDescription = trailingDescription
        self.trailingDescriptionColor = trailingDescriptionColor ?? Color(
            light: .palette.grey600,
            dark: .palette.dark200
        )
        self.tags = tags
        self.leading = leading()
        self.graph = graph()
    }

    public var body: some View {
        HStack(alignment: .customRowVerticalAlignment, spacing: 16) {
            leading
            VStack(alignment: .leading, spacing: 8) {
                mainContent()
                if !tags.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(0..<tags.count) { index in
                            tags[index]
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Spacing.padding3)
        .padding(.vertical, Spacing.padding2)
        .background(Color.semantic.background)
    }

    @ViewBuilder private var leadingTitleView: some View {
        Text(leadingTitle)
            .typography(.body2)
            .foregroundColor(.semantic.title)
    }

    @ViewBuilder private var leadingSubtitleView: some View {
        if let leadingSubtitle = leadingSubtitle {
            Text(leadingSubtitle)
                .typography(.paragraph2)
                .foregroundColor(.semantic.title)
        }
    }

    @ViewBuilder private var leadingDescriptionView: some View {
        Text(leadingDescription)
            .typography(.paragraph1)
            .foregroundColor(
                Color(
                    light: .palette.grey600,
                    dark: .palette.dark200
                )
            )
    }

    @ViewBuilder private var trailingTitleView: some View {
        if graph is EmptyView {
            Text(trailingTitle)
                .typography(.body2)
                .foregroundColor(.semantic.title)
        } else {
            Text(trailingTitle)
                .typography(.paragraph2)
                .foregroundColor(.semantic.title)
        }
    }

    @ViewBuilder private var trailingDescriptionView: some View {
        Text(trailingDescription)
            .typography(.paragraph1)
            .foregroundColor(trailingDescriptionColor)
    }

    @ViewBuilder private func mainContent() -> some View {
        if leadingSubtitle == nil, graph is EmptyView {
            defaultContent()
        } else if leadingSubtitle == nil, !(graph is EmptyView) {
            fullContentNoSubtitle()
        } else if graph is EmptyView {
            fullContentNoGraph()
        } else {
            fullContent()
        }
    }

    @ViewBuilder private func defaultContent() -> some View {
        VStack(spacing: mainContentSpacing) {
            pair(leadingTitleView, trailingTitleView)
            pair(leadingDescriptionView, trailingDescriptionView)
        }
        .alignmentGuide(.customRowVerticalAlignment) {
            $0[VerticalAlignment.center]
        }
    }

    @ViewBuilder private func fullContent() -> some View {
        VStack(spacing: mainContentSpacing) {
            VStack(spacing: mainContentSpacing) {
                pair(leadingTitleView, graph)
                pair(leadingSubtitleView, trailingTitleView)
            }
            .alignmentGuide(.customRowVerticalAlignment) {
                $0[VerticalAlignment.center]
            }
            pair(leadingDescriptionView, trailingDescriptionView)
        }
    }

    @ViewBuilder private func fullContentNoGraph() -> some View {
        VStack(spacing: mainContentSpacing) {
            VStack(spacing: mainContentSpacing) {
                pair(leadingTitleView, trailingTitleView)
                pair(leadingSubtitleView, trailingDescriptionView)
            }
            .alignmentGuide(.customRowVerticalAlignment) {
                $0[VerticalAlignment.center]
            }
            pair(leadingDescriptionView, Spacer())
        }
    }

    @ViewBuilder private func fullContentNoSubtitle() -> some View {
        VStack(spacing: mainContentSpacing) {
            VStack(spacing: mainContentSpacing) {
                pair(leadingTitleView, graph)
                pair(leadingDescriptionView, trailingTitleView)
            }
            .alignmentGuide(.customRowVerticalAlignment) {
                $0[VerticalAlignment.center]
            }
            pair(Spacer(), trailingDescriptionView)
        }
    }

    @ViewBuilder private func pair<Leading: View, Trailing: View>(
        _ leading: Leading,
        _ trailing: Trailing
    ) -> some View {
        HStack {
            leading
            Spacer()
            trailing
        }
    }
}

extension BalanceRow where Graph == EmptyView {

    public init(
        leadingTitle: String,
        leadingSubtitle: String? = nil,
        leadingDescription: String,
        trailingTitle: String,
        trailingDescription: String,
        trailingDescriptionColor: Color? = nil,
        tags: [Tag] = [],
        @ViewBuilder leading: () -> Leading
    ) {
        self.init(
            leadingTitle: leadingTitle,
            leadingSubtitle: leadingSubtitle,
            leadingDescription: leadingDescription,
            trailingTitle: trailingTitle,
            trailingDescription: trailingDescription,
            trailingDescriptionColor: trailingDescriptionColor,
            tags: tags,
            leading: leading
        ) {
            EmptyView()
        }
    }
}

// swiftlint:disable closure_body_length
struct BalanceRow_Previews: PreviewProvider {

    static var previews: some View {
        Group {
            BalanceRow(
                leadingTitle: "Bitcoin",
                leadingDescription: "BTC",
                trailingTitle: "$44,403.13",
                trailingDescription: "↓ 12.32%",
                trailingDescriptionColor: .semantic.error
            ) {
                Icon.trade
                    .fixedSize()
                    .accentColor(.semantic.warning)
            }
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Default Balance Row")

            BalanceRow(
                leadingTitle: "Trading Account",
                leadingDescription: "Bitcoin",
                trailingTitle: "$7,926.43",
                trailingDescription: "0.00039387 BTC",
                tags: [
                    Tag(text: "No Fees", variant: .success),
                    Tag(text: "Faster", variant: .success),
                    Tag(text: "Warning Alert", variant: .warning)
                ]
            ) {
                Icon.trade
                    .fixedSize()
                    .accentColor(.semantic.primary)
            }
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Row with tags")

            BalanceRow(
                leadingTitle: "BTC - USD",
                leadingDescription: "Limit Buy - Open",
                trailingTitle: "0.5736523 BTC",
                trailingDescription: "$15,482.86"
            ) {
                Icon.moneyUSD
                    .fixedSize()
                    .accentColor(.semantic.warning)
            }
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Default Balance Row")

            BalanceRow(
                leadingTitle: "Bitcoin",
                leadingSubtitle: "$15,879.90",
                leadingDescription: "0.3576301941 BTC",
                trailingTitle: "$44,403.13",
                trailingDescription: "↓ 12.32%",
                trailingDescriptionColor: .semantic.error,
                leading: {
                    Icon.trade
                        .fixedSize()
                        .accentColor(.semantic.warning)
                },
                graph: {
                    graph
                }
            )
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Full Content")

            BalanceRow(
                leadingTitle: "Bitcoin",
                leadingDescription: "0.3576301941 BTC",
                trailingTitle: "$44,403.13",
                trailingDescription: "↓ 12.32%",
                trailingDescriptionColor: .semantic.error,
                leading: {
                    Icon.trade
                        .fixedSize()
                        .accentColor(.semantic.warning)
                },
                graph: {
                    graph
                }
            )
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Full Content no leading subtitle")

            BalanceRow(
                leadingTitle: "Bitcoin",
                leadingSubtitle: "$15,879.90",
                leadingDescription: "0.3576301941 BTC",
                trailingTitle: "$44,403.13",
                trailingDescription: "↓ 12.32%",
                trailingDescriptionColor: .semantic.error
            ) {
                Icon.trade
                    .fixedSize()
                    .accentColor(.semantic.warning)
            }
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Full Content no graph")
        }
        .frame(width: 375)
    }

    @ViewBuilder static var graph: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 16))
            path.addQuadCurve(
                to: CGPoint(x: 16, y: 8),
                control: CGPoint(x: 8, y: -8)
            )
            path.addQuadCurve(
                to: CGPoint(x: 40, y: 6),
                control: CGPoint(x: 25, y: 20)
            )
            path.addQuadCurve(
                to: CGPoint(x: 64, y: 8),
                control: CGPoint(x: 50, y: 0)
            )
        }
        .stroke(Color.semantic.primary, lineWidth: 2)
        .frame(width: 64, height: 16)
    }
}
