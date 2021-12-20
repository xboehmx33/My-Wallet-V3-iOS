// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import ERC20Kit
import EthereumKit
import MoneyKit
import PlatformKit
import ToolKit

final class ERC20TokenAccountsRepositoryMock: ERC20TokenAccountsRepositoryAPI {

    // MARK: - Private Properties

    private let tokenAccounts: ERC20TokenAccounts

    // MARK: - Setup

    /// Creates a mock ERC-20 token accounts repository.
    ///
    /// - Parameter cryptoCurrency: An ERC-20 crypto currency.
    init(cryptoCurrency: CryptoCurrency) {
        tokenAccounts = .stubbed(cryptoCurrency: cryptoCurrency)
    }

    // MARK: - Internal Methods

    func tokens(
        for address: EthereumAddress,
        forceFetch: Bool
    ) -> AnyPublisher<ERC20TokenAccounts, ERC20TokenAccountsError> {
        .just(tokenAccounts)
    }

    func tokensStream(
        for address: EthereumAddress,
        skipStale: Bool
    ) -> StreamOf<ERC20TokenAccounts, ERC20TokenAccountsError> {
        .just(.success(tokenAccounts))
    }

    func invalidateERC20TokenAccountsForAddress(
        _ address: EthereumAddress
    ) {
        // no-op
    }
}
