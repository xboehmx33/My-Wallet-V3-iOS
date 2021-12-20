// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
import DIKit
import Foundation
import MoneyKit
import PlatformKit
import RxCocoa
import RxSwift
import stellarsdk

protocol HorizonProxyAPI {
    func accountResponse(for accountID: String) -> Single<AccountResponse>
    func minimumBalance(subentryCount: UInt) -> CryptoValue
    func sign(transaction: stellarsdk.Transaction, keyPair: stellarsdk.KeyPair) -> Completable
    func submitTransaction(transaction: stellarsdk.Transaction) -> Single<TransactionPostResponseEnum>
}

final class HorizonProxy: HorizonProxyAPI {

    // MARK: Private Properties

    private let configurationService: StellarConfigurationAPI
    private let walletOptions: WalletOptionsAPI
    private let accountRepository: StellarWalletAccountRepositoryAPI
    private var configuration: Single<StellarConfiguration> {
        configurationService.configuration
    }

    private let minReserve = BigInt(5000000)

    init(
        configurationService: StellarConfigurationAPI = resolve(),
        accountRepository: StellarWalletAccountRepositoryAPI = resolve(),
        walletOptions: WalletOptionsAPI = resolve()
    ) {
        self.configurationService = configurationService
        self.walletOptions = walletOptions
        self.accountRepository = accountRepository
    }

    func sign(transaction: stellarsdk.Transaction, keyPair: stellarsdk.KeyPair) -> Completable {
        configuration.map(\.network)
            .flatMapCompletable(weak: self) { (self, network) -> Completable in
                self.sign(transaction: transaction, keyPair: keyPair, network: network)
            }
    }

    private func sign(transaction: stellarsdk.Transaction, keyPair: stellarsdk.KeyPair, network: Network) -> Completable {
        Completable.fromCallable {
            try transaction.sign(keyPair: keyPair, network: network)
        }
    }

    func minimumBalance(subentryCount: UInt) -> CryptoValue {
        CryptoValue(amount: BigInt(2 + subentryCount) * minReserve, currency: .coin(.stellar))
    }

    func accountResponse(for accountID: String) -> Single<AccountResponse> {
        configuration
            .map(\.sdk.accounts)
            .flatMap { service -> Single<AccountResponse> in
                Single<AccountResponse>.create { event -> Disposable in
                    service.getAccountDetails(
                        accountId: accountID,
                        response: { response -> Void in
                            switch response {
                            case .success(details: let details):
                                event(.success(details))
                            case .failure(error: let error):
                                event(.error(error.toStellarServiceError()))
                            }
                        }
                    )
                    return Disposables.create()
                }
            }
    }

    func submitTransaction(transaction: stellarsdk.Transaction) -> Single<TransactionPostResponseEnum> {
        configuration.flatMap(weak: self) { (self, configuration) -> Single<TransactionPostResponseEnum> in
            self.submitTransaction(transaction: transaction, with: configuration)
        }
    }

    private func submitTransaction(
        transaction: stellarsdk.Transaction,
        with configuration: StellarConfiguration
    ) -> Single<TransactionPostResponseEnum> {
        Single.create(weak: self) { _, observer -> Disposable in
            do {
                try configuration.sdk.transactions
                    .submitTransaction(transaction: transaction) { response in
                        observer(.success(response))
                    }
            } catch {
                observer(.error(error))
            }
            return Disposables.create()
        }
    }
}
