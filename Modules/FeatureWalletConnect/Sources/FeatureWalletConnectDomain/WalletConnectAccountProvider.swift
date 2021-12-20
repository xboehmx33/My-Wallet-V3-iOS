// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import Foundation
import PlatformKit

public protocol WalletConnectAccountProviderAPI {
    var defaultAccount: AnyPublisher<SingleAccount, CryptoAssetError> { get }
}

final class WalletConnectAccountProvider {

    private let coincore: CoincoreAPI

    init(coincore: CoincoreAPI = resolve()) {
        self.coincore = coincore
    }
}

extension WalletConnectAccountProvider: WalletConnectAccountProviderAPI {
    var defaultAccount: AnyPublisher<SingleAccount, CryptoAssetError> {
        coincore[.coin(.ethereum)]
            .defaultAccount
    }
}

extension WalletConnectAccountProvider: WalletConnectPublicKeyProviderAPI {
    var publicKey: AnyPublisher<String, Error> {
        defaultAccount
            .eraseError()
            .flatMap { account -> AnyPublisher<String, Error> in
                account.receiveAddress
                    .map { address in address.address }
                    .asPublisher()
                    .eraseError()
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}
