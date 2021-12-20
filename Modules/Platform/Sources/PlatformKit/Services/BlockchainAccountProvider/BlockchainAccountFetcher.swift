// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import MoneyKit
import RxSwift

public protocol BlockchainAccountFetching {
    func account(for currencyType: CurrencyType, accountType: SingleAccountType) -> Single<BlockchainAccount>
}

final class BlockchainAccountFetcher: BlockchainAccountFetching {

    private let blockchainAccountProvider: BlockchainAccountProviding

    init(blockchainAccountProvider: BlockchainAccountProviding = resolve()) {
        self.blockchainAccountProvider = blockchainAccountProvider
    }

    // MARK: - BlockchainAccountFetching

    func account(for currencyType: CurrencyType, accountType: SingleAccountType) -> Single<BlockchainAccount> {
        blockchainAccountProvider
            .account(
                for: currencyType,
                accountType: accountType
            )
    }
}
