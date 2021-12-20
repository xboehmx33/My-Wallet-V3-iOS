// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Charts
import ComposableArchitectureExtensions
import MoneyKit
import PlatformKit

/// Any util / data related to the pie chart presentation / interaction layers
public enum AssetLineChart {

    public enum State {
        public typealias Interaction = LoadingState<AssetLineChart.Value.Interaction>
        public typealias Presentation = LoadingState<(AssetLineChartMarkerView.Theme, LineChartData)>
    }

    // MARK: - Value namespace

    public enum Value {

        /// Value for the interaction level
        public struct Interaction {

            /// Percent change of the dataset
            let delta: Double

            /// The asset type
            let currency: CryptoCurrency

            /// Prices for the dataset
            let prices: [PriceQuoteAtTime]
        }

        /// A presentation value
        public struct Presentation: CustomDebugStringConvertible {

            public let debugDescription: String

            /// The color of the asset
            let color: UIColor

            /// The percentage of the asset from the total of 100%
            let points: [CGPoint]

            init(value: Interaction) {
                debugDescription = value.currency.displayCode
                color = value.delta >= 0 ? .positivePrice : .negativePrice
                points = value.prices.enumerated().map { offset, element in
                    CGPoint(
                        x: Double(offset),
                        y: element.moneyValue.displayMajorValue.doubleValue
                    )
                }
            }
        }
    }
}

extension AssetLineChart.State.Presentation {
    var visibility: Visibility {
        switch self {
        case .loading:
            return .hidden
        case .loaded:
            return .visible
        }
    }
}
