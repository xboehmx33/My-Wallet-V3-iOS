// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import FeatureTransactionDomain
import Foundation
import PlatformKit

struct WalletConnectEngineFactory: WalletConnectEngineFactoryAPI {
    func build(
        target: TransactionTarget
    ) -> TransactionEngine {
        switch target {
        case is EthereumSignMessageTarget:
            return WalletConnectSignMessageEngine()
        case is EthereumSendTransactionTarget:
            return WalletConnectTransactionEngine(requireSecondPassword: false)
        default:
            fatalError("Transaction target '\(type(of: target))' not supported.")
        }
    }
}
