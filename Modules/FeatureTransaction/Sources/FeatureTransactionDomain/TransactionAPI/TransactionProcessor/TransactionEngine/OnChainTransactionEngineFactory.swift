// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation
import PlatformKit

public protocol OnChainTransactionEngineFactory {
    func build(requiresSecondPassword: Bool) -> OnChainTransactionEngine
}

public protocol WalletConnectEngineFactoryAPI {
    func build(target: TransactionTarget) -> TransactionEngine
}
