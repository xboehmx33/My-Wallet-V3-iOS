// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import FeatureTransactionDomain
import MoneyKit
import PlatformKit
import RxSwift
import ToolKit

final class TargetSelectionInteractor {

    private let coincore: CoincoreAPI
    private let linkedBanksFactory: LinkedBanksFactoryAPI
    private let featureFetcher: FeatureFetching
    private let nameResolutionService: BlockchainNameResolutionServiceAPI

    init(
        coincore: CoincoreAPI = resolve(),
        nameResolutionService: BlockchainNameResolutionServiceAPI = resolve(),
        featureFetcher: FeatureFetching = resolve(),
        linkedBanksFactory: LinkedBanksFactoryAPI = resolve()
    ) {
        self.coincore = coincore
        self.linkedBanksFactory = linkedBanksFactory
        self.featureFetcher = featureFetcher
        self.nameResolutionService = nameResolutionService
    }

    func getBitPayInvoiceTarget(data: String, asset: CryptoCurrency) -> Single<BitPayInvoiceTarget> {
        BitPayInvoiceTarget.make(from: data, asset: .coin(.bitcoin))
    }

    func getAvailableTargetAccounts(
        sourceAccount: BlockchainAccount,
        action: AssetAction
    ) -> Single<[SingleAccount]> {
        switch action {
        case .swap,
             .send,
             .interestWithdraw,
             .interestTransfer:
            return Single.just(sourceAccount)
                .flatMap(weak: self) { (self, account) -> Single<[SingleAccount]> in
                    self.coincore
                        .getTransactionTargets(
                            sourceAccount: account,
                            action: action
                        )
                        .asObservable()
                        .asSingle()
                }
        case .deposit:
            return linkedBanksFactory.nonWireTransferBanks.map { $0.map { $0 as SingleAccount } }
        case .withdraw:
            return linkedBanksFactory.linkedBanks.map { $0.map { $0 as SingleAccount } }
        case .sign,
             .receive,
             .buy,
             .sell,
             .viewActivity:
            unimplemented()
        }
    }

    func validateCrypto(address: String, account: BlockchainAccount) -> Single<Result<ReceiveAddress, Error>> {
        guard let crypto = account as? CryptoAccount else {
            fatalError("You cannot validate an address using this account type: \(account)")
        }
        let asset = coincore[crypto.asset]
        return asset
            .parse(address: address)
            .asObservable()
            .asSingle()
            .flatMap(weak: self) { (self, validatedAddress) -> Single<Result<ReceiveAddress, Error>> in
                guard let validatedAddress = validatedAddress else {
                    return self.validate(domainName: address, currency: crypto.asset)
                }
                return .just(.success(validatedAddress))
            }
    }

    private func validate(domainName: String, currency: CryptoCurrency) -> Single<Result<ReceiveAddress, Error>> {
        nameResolutionService
            .validate(domainName: domainName, currency: currency)
            .asObservable()
            .take(1)
            .asSingle()
            .map { receiveAddress -> Result<ReceiveAddress, Error> in
                switch receiveAddress {
                case .some(let receiveAddress):
                    return .success(receiveAddress)
                case .none:
                    return .failure(CryptoAssetError.addressParseFailure)
                }
            }
    }
}
