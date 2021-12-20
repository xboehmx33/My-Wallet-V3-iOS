// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComposableArchitectureExtensions
import Localization
import MoneyKit
import PlatformKit

public enum DashboardAsset {

    // MARK: - State Aliases

    public enum State {}

    // MARK: - Value Namespace

    public enum Value {
        // MARK: - Interaction

        /// The interaction value of dashboard asset
        public enum Interaction {}

        // MARK: - Presentation

        public enum Presentation {}
    }
}

extension PriceWindow {

    public typealias Time = DashboardAsset.Value.Interaction.AssetPrice.Time

    public func time(for currency: CryptoCurrency) -> Time {
        switch self {
        case .all:
            return .all
        case .year:
            return .years(1)
        case .month:
            return .months(1)
        case .week:
            return .weeks(1)
        case .day:
            return .hours(24)
        }
    }
}
