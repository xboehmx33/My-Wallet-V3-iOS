// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComposableArchitectureExtensions
import MoneyKit
import PlatformKit
import UIKit

public enum FiatBalanceViewAsset {

    public enum State {
        public typealias Interaction = LoadingState<Value.Interaction>
        public typealias Presentation = LoadingState<Value.Presentation>
    }

    // MARK: - Value Namespace

    public enum Value {

        // MARK: - Interaction

        public struct Interaction {
            /// The balance
            public let base: MoneyValue

            /// The converted value if the
            /// balance currency type does not
            /// match the user's preferred currency
            public let quote: MoneyValue
        }

        public struct Presentation {

            public enum QuoteFiatContent {
                case visible(LabelContent)
                case hidden

                public var isHidden: Bool {
                    quoteVisibility.isHidden
                }

                public var quoteVisibility: Visibility {
                    switch self {
                    case .visible:
                        return .visible
                    case .hidden:
                        return .hidden
                    }
                }
            }

            // MARK: - Properties

            let baseBalanceLabelContent: LabelContent
            let quoteBalanceLabelContent: QuoteFiatContent

            /// Descriptors that allows customized content and style
            public struct Descriptors {
                let baseFiatFont: UIFont
                let baseFiatTextColor: UIColor
                let baseFiatAccessibility: Accessibility

                let quoteFiatFont: UIFont
                let quoteFiatTextColor: UIColor
                let quoteFiatAccessibility: Accessibility

                public init(
                    baseFiatFont: UIFont,
                    baseFiatTextColor: UIColor,
                    baseFiatAccessibility: Accessibility,
                    quoteFiatFont: UIFont,
                    quoteFiatTextColor: UIColor,
                    quoteFiatAccessibility: Accessibility
                ) {
                    self.baseFiatFont = baseFiatFont
                    self.baseFiatTextColor = baseFiatTextColor
                    self.baseFiatAccessibility = baseFiatAccessibility
                    self.quoteFiatFont = quoteFiatFont
                    self.quoteFiatTextColor = quoteFiatTextColor
                    self.quoteFiatAccessibility = quoteFiatAccessibility
                }
            }

            // MARK: - Setup

            public init(with value: Interaction, descriptors: Descriptors) {
                let showsQuoteValue = value.quote.currency != value.base.currency
                let baseFont: UIFont
                let baseColor: UIColor
                if showsQuoteValue {
                    quoteBalanceLabelContent = .visible(
                        LabelContent(
                            text: value.quote.toDisplayString(includeSymbol: true),
                            font: descriptors.quoteFiatFont,
                            color: descriptors.quoteFiatTextColor,
                            alignment: .right,
                            adjustsFontSizeToFitWidth: .true(factor: 0.4),
                            accessibility: .id("\(descriptors.quoteFiatAccessibility.id!)\(value.quote.code)")
                        )
                    )
                    baseFont = descriptors.baseFiatFont
                    baseColor = descriptors.baseFiatTextColor
                } else {
                    quoteBalanceLabelContent = .hidden
                    baseFont = descriptors.quoteFiatFont
                    baseColor = descriptors.quoteFiatTextColor
                }

                baseBalanceLabelContent = LabelContent(
                    text: value.base.toDisplayString(includeSymbol: true),
                    font: baseFont,
                    color: baseColor,
                    alignment: .right,
                    accessibility: .id("\(descriptors.baseFiatAccessibility.id.printable)\(value.base.code)")
                )
            }
        }
    }
}

extension FiatBalanceViewAsset.Value.Presentation.Descriptors {
    public typealias Descriptors = FiatBalanceViewAsset.Value.Presentation.Descriptors

    public static func `default`(
        fiatAccessiblitySuffix: String,
        baseFiatAccessibilitySuffix: String? = nil
    ) -> Descriptors {
        var baseAccessibility: Accessibility = .none
        if let base = baseFiatAccessibilitySuffix {
            baseAccessibility = .id(base)
        }
        return Descriptors(
            baseFiatFont: .main(.medium, 14.0),
            baseFiatTextColor: .descriptionText,
            baseFiatAccessibility: .id("\(fiatAccessiblitySuffix)"),
            quoteFiatFont: .main(.semibold, 16.0),
            quoteFiatTextColor: .titleText,
            quoteFiatAccessibility: baseAccessibility
        )
    }
}

extension FiatBalanceViewAsset.Value.Presentation.Descriptors {
    public typealias DashboardAccessibility = Accessibility.Identifier.Dashboard.FiatCustodialCell

    public static func dashboard(baseAccessibilitySuffix: String, quoteAccessibilitySuffix: String) -> Descriptors {
        .init(
            baseFiatFont: .main(.medium, 14),
            baseFiatTextColor: .descriptionText,
            baseFiatAccessibility: .id("\(DashboardAccessibility.baseFiatBalance).\(baseAccessibilitySuffix)"),
            quoteFiatFont: .main(.semibold, 20),
            quoteFiatTextColor: .textFieldText,
            quoteFiatAccessibility: .id("\(DashboardAccessibility.quoteFiatBalance).\(quoteAccessibilitySuffix)")
        )
    }

    public static func paymentMethods(baseAccessibilitySuffix: String, quoteAccessibilitySuffix: String) -> Descriptors {
        .init(
            baseFiatFont: .main(.medium, 14),
            baseFiatTextColor: .descriptionText,
            baseFiatAccessibility: .id("\(DashboardAccessibility.baseFiatBalance).\(baseAccessibilitySuffix)"),
            quoteFiatFont: .main(.semibold, 16),
            quoteFiatTextColor: .textFieldText,
            quoteFiatAccessibility: .id("\(DashboardAccessibility.quoteFiatBalance).\(quoteAccessibilitySuffix)")
        )
    }
}

extension LoadingState where Content == FiatBalanceViewAsset.Value.Presentation {
    init(
        with state: LoadingState<FiatBalanceViewAsset.Value.Interaction>,
        descriptors: FiatBalanceViewAsset.Value.Presentation.Descriptors
    ) {
        switch state {
        case .loading:
            self = .loading
        case .loaded(next: let content):
            self = .loaded(
                next: .init(
                    with: content,
                    descriptors: descriptors
                )
            )
        }
    }
}
