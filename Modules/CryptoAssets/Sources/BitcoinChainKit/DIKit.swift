// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import FeatureTransactionDomain
import PlatformKit

extension DependencyContainer {

    // MARK: - BitcoinChainKit Module

    public static var bitcoinChainKit = module {

        // MARK: - Bitcoin

        factory(tag: BitcoinChainCoin.bitcoin) { APIClient(coin: .bitcoin) as APIClientAPI }

        single(tag: BitcoinChainCoin.bitcoin) { BalanceService(coin: .bitcoin) as BalanceServiceAPI }

        factory(tag: BitcoinChainCoin.bitcoin) { AnyCryptoFeeService<BitcoinChainTransactionFee<BitcoinToken>>.bitcoin() }

        factory(tag: BitcoinChainCoin.bitcoin) {
            BitcoinExternalAssetAddressFactory() as ExternalAssetAddressFactory
        }

        factory { CryptoFeeService<BitcoinChainTransactionFee<BitcoinToken>>() }

        // MARK: - Bitcoin Cash

        factory(tag: BitcoinChainCoin.bitcoinCash) { APIClient(coin: .bitcoinCash) as APIClientAPI }

        single(tag: BitcoinChainCoin.bitcoinCash) { BalanceService(coin: .bitcoinCash) as BalanceServiceAPI }

        factory(tag: BitcoinChainCoin.bitcoinCash) { AnyCryptoFeeService<BitcoinChainTransactionFee<BitcoinCashToken>>.bitcoinCash() }

        factory(tag: BitcoinChainCoin.bitcoinCash) {
            BitcoinCashExternalAssetAddressFactory() as ExternalAssetAddressFactory
        }

        factory { CryptoFeeService<BitcoinChainTransactionFee<BitcoinCashToken>>() }
    }
}

extension AnyCryptoFeeService where FeeType == BitcoinChainTransactionFee<BitcoinToken> {
    fileprivate static func bitcoin(
        service: CryptoFeeService<BitcoinChainTransactionFee<BitcoinToken>> = resolve()
    ) -> AnyCryptoFeeService<FeeType> {
        AnyCryptoFeeService<FeeType>(service: service)
    }
}

extension AnyCryptoFeeService where FeeType == BitcoinChainTransactionFee<BitcoinCashToken> {
    fileprivate static func bitcoinCash(
        service: CryptoFeeService<BitcoinChainTransactionFee<BitcoinCashToken>> = resolve()
    ) -> AnyCryptoFeeService<FeeType> {
        AnyCryptoFeeService<FeeType>(service: service)
    }
}
