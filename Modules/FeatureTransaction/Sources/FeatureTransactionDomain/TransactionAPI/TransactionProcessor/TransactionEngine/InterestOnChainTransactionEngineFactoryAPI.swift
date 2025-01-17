// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import PlatformKit

public protocol InterestOnChainTransactionEngineFactoryAPI {
    func build(
        requiresSecondPassword: Bool,
        action: AssetAction,
        onChainEngine: OnChainTransactionEngine
    ) -> InterestTransactionEngine
}
