// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Charts
import ComposableArchitectureExtensions
import MoneyKit
import PlatformKit

/// Any util / data related to the pie chart presentation / interaction layers
public enum AssetPieChart {

    public enum State {
        public typealias Interaction = LoadingState<[AssetPieChart.Value.Interaction]>
        public typealias Presentation = LoadingState<PieChartData>
    }

    // MARK: - Value namespace

    public enum Value {

        /// Value for the interaction level
        public struct Interaction: Equatable {

            /// The asset type
            let asset: CurrencyType

            /// Percentage that the asset takes off the total
            let percentage: Double

            init(asset: CurrencyType, percentage: MoneyValue) {
                self.asset = asset
                self.percentage = percentage.displayMajorValue.doubleValue
            }
        }

        /// A presentation value
        public struct Presentation: CustomDebugStringConvertible {

            public let debugDescription: String

            /// The color of the asset
            let color: UIColor

            /// The percentage of the asset from the total of 100%
            let percentage: Double

            public init(value: Interaction) {
                debugDescription = value.asset.displayCode
                color = value.asset.brandUIColor
                percentage = value.percentage
            }
        }
    }
}
