// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
@testable import FeatureTransactionUI
import MoneyKit
import PlatformKit
import UIKit

public final class MockLegacyBuyFlowRouter: LegacyBuyFlowRouting {

    public struct RecordedInvocations {
        public var presentBuyScreen: Int = 0
        public var presentBuyFlowWithTargetCurrencySelectionIfNecessary: Int = 0
    }

    public private(set) var recordedInvocations = RecordedInvocations()

    public func presentBuyScreen(
        from presenter: UIViewController,
        targetCurrency: CryptoCurrency,
        isSDDEligible: Bool = true
    ) -> AnyPublisher<TransactionFlowResult, Never> {
        recordedInvocations.presentBuyScreen += 1
        return .empty()
    }

    public func presentBuyFlowWithTargetCurrencySelectionIfNecessary(
        from presenter: UIViewController
    ) -> AnyPublisher<TransactionFlowResult, Never> {
        recordedInvocations.presentBuyFlowWithTargetCurrencySelectionIfNecessary += 1
        return .empty()
    }
}
