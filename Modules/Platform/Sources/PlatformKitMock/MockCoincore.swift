// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import MoneyKit
import PlatformKit
import RxSwift

final class MockCoincore: CoincoreAPI {

    var allAccounts: AnyPublisher<AccountGroup, CoincoreError> = .empty()
    var allAssets: [Asset] = []
    var fiatAsset: Asset = MockAsset()
    var cryptoAssets: [CryptoAsset] = []

    var initializePublisherCalled = false

    func initialize() -> AnyPublisher<Void, CoincoreError> {
        initializePublisherCalled = true
        return .just(())
    }

    func getTransactionTargets(
        sourceAccount: BlockchainAccount,
        action: AssetAction
    ) -> AnyPublisher<[SingleAccount], CoincoreError> {
        .just([])
    }

    var requestedCryptoAsset: CryptoAsset!

    subscript(cryptoCurrency: CryptoCurrency) -> CryptoAsset {
        requestedCryptoAsset
    }
}

class MockAsset: Asset {

    func accountGroup(filter: AssetFilter) -> AnyPublisher<AccountGroup, Never> {
        .empty()
    }

    func transactionTargets(account: SingleAccount) -> AnyPublisher<[SingleAccount], Never> {
        .empty()
    }

    func parse(address: String) -> AnyPublisher<ReceiveAddress?, Never> {
        .empty()
    }
}
