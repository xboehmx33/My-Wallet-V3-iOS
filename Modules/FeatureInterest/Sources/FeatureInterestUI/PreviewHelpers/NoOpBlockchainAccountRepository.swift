// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import MoneyKit
import PlatformKit

final class NoOpBlockchainAccountRepository: BlockchainAccountRepositoryAPI {
    func fetchAccountWithAddresss(
        _ address: String,
        currencyType: CurrencyType
    ) -> AnyPublisher<BlockchainAccount, BlockchainAccountRepositoryError> {
        Empty().eraseToAnyPublisher()
    }

    func accountsWithCurrencyType(
        _ currency: CurrencyType
    ) -> AnyPublisher<[BlockchainAccount], BlockchainAccountRepositoryError> {
        Empty().eraseToAnyPublisher()
    }

    func accountsWithSingleAccountType(
        _ accountType: SingleAccountType
    ) -> AnyPublisher<[BlockchainAccount], BlockchainAccountRepositoryError> {
        Empty().eraseToAnyPublisher()
    }

    func accountsWithCurrencyType(
        _ currency: CurrencyType,
        accountType: SingleAccountType
    ) -> AnyPublisher<[BlockchainAccount], BlockchainAccountRepositoryError> {
        Empty().eraseToAnyPublisher()
    }

    func accountWithCurrencyType(
        _ currency: CurrencyType,
        accountType: SingleAccountType
    ) -> AnyPublisher<BlockchainAccount, BlockchainAccountRepositoryError> {
        Empty().eraseToAnyPublisher()
    }

    func accountsAvailableToPerformAction(
        _ assetAction: AssetAction,
        target: BlockchainAccount
    ) -> AnyPublisher<[BlockchainAccount], BlockchainAccountRepositoryError> {
        Empty().eraseToAnyPublisher()
    }
}
