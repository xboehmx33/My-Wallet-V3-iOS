// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import FeatureTransactionDomain

class EthereumOnChainTransactionEngineFactory: OnChainTransactionEngineFactory {
    func build(requiresSecondPassword: Bool) -> OnChainTransactionEngine {
        EthereumOnChainTransactionEngine(requireSecondPassword: requiresSecondPassword)
    }
}
