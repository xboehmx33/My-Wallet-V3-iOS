// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
import DIKit
import FeatureTransactionDomain
import MoneyKit
import PlatformKit
import RxSwift
import stellarsdk
import ToolKit

final class StellarTransactionDispatcher {

    // MARK: Types

    private typealias StellarTransaction = stellarsdk.Transaction

    // MARK: Private Properties

    private let walletOptions: WalletOptionsAPI
    private let accountRepository: StellarWalletAccountRepositoryAPI
    private let horizonProxy: HorizonProxyAPI

    private let minSend = CryptoValue(amount: 1, currency: .coin(.stellar))
    private var sendTimeOutSeconds: Single<Int> {
        walletOptions.walletOptions
            .map(\.xlmMetadata?.sendTimeOutSeconds)
            .map { $0 ?? 10 }
            .catchErrorJustReturn(10)
    }

    init(
        accountRepository: StellarWalletAccountRepositoryAPI = resolve(),
        walletOptions: WalletOptionsAPI = resolve(),
        horizonProxy: HorizonProxyAPI = resolve()
    ) {
        self.walletOptions = walletOptions
        self.accountRepository = accountRepository
        self.horizonProxy = horizonProxy
    }

    // MARK: Methods

    func dryRunTransaction(sendDetails: SendDetails) -> Completable {
        checkInput(sendDetails: sendDetails)
            .andThen(checkDestinationAddress(sendDetails: sendDetails))
            .andThen(checkMinimumSend(sendDetails: sendDetails))
            .andThen(checkDestinationAccount(sendDetails: sendDetails))
            .andThen(checkSourceAccount(sendDetails: sendDetails))
            .andThen(transaction(sendDetails: sendDetails).asCompletable())
    }

    func isExchangeAddresses(address: String) -> Single<Bool> {
        walletOptions.walletOptions
            .map(\.xlmExchangeAddresses)
            .map { addresses -> Bool in
                guard let addresses = addresses else {
                    return false
                }
                return addresses
                    .contains(where: { $0.caseInsensitiveCompare(address) == .orderedSame })
            }
    }

    func isAddressValid(address: String) -> Bool {
        do {
            _ = try stellarsdk.KeyPair(accountId: address)
            return true
        } catch {
            return false
        }
    }

    func sendFunds(sendDetails: SendDetails, secondPassword: String) -> Single<SendConfirmationDetails> {
        Single
            .zip(
                accountRepository.loadKeyPair(with: secondPassword),
                transaction(sendDetails: sendDetails)
            )
            .flatMap(weak: self) { (self, payload) -> Single<TransactionPostResponseEnum> in
                let (keyPair, transaction) = payload
                let sdkKeyPair = try stellarsdk.KeyPair(secretSeed: keyPair.secret)
                return self.horizonProxy
                    .sign(transaction: transaction, keyPair: sdkKeyPair)
                    .andThen(self.horizonProxy.submitTransaction(transaction: transaction))
            }
            .map { response -> SendConfirmationDetails in
                try response.toSendConfirmationDetails(sendDetails: sendDetails)
            }
    }

    // MARK: Private Methods

    private func checkInput(sendDetails: SendDetails) -> Completable {
        guard sendDetails.value.currencyType == .coin(.stellar) else {
            return .error(SendFailureReason.unknown)
        }
        guard sendDetails.fee.currencyType == .coin(.stellar) else {
            return .error(SendFailureReason.unknown)
        }
        return .empty()
    }

    private func checkDestinationAddress(sendDetails: SendDetails) -> Completable {
        do {
            _ = try stellarsdk.KeyPair(accountId: sendDetails.toAddress)
        } catch {
            return .error(SendFailureReason.badDestinationAccountID)
        }
        return .empty()
    }

    private func checkSourceAccount(sendDetails: SendDetails) -> Completable {
        horizonProxy.accountResponse(for: sendDetails.fromAddress)
            .map(weak: self) { (self, response) -> AccountResponse in
                let total = try sendDetails.value + sendDetails.fee
                let minBalance = self.horizonProxy.minimumBalance(subentryCount: response.subentryCount)
                if try response.totalBalance < (total + minBalance) {
                    throw SendFailureReason.insufficientFunds(response.totalBalance.moneyValue, total.moneyValue)
                }
                return response
            }
            .asCompletable()
    }

    private func checkMinimumSend(sendDetails: SendDetails) -> Completable {
        do {
            if try sendDetails.value < minSend {
                return .error(SendFailureReason.belowMinimumSend(minSend.moneyValue))
            }
        } catch {
            return .error(SendFailureReason.unknown)
        }
        return .empty()
    }

    private func checkDestinationAccount(sendDetails: SendDetails) -> Completable {
        let minBalance = horizonProxy.minimumBalance(subentryCount: 0)
        return horizonProxy.accountResponse(for: sendDetails.toAddress)
            .asCompletable()
            .catchError { error -> Completable in
                switch error {
                case StellarAccountError.noDefaultAccount:
                    if try sendDetails.value < minBalance {
                        return .error(SendFailureReason.belowMinimumSendNewAccount(minBalance.moneyValue))
                    }
                    return .empty()
                default:
                    throw error
                }
            }
    }

    private func submitTransaction(
        transaction: StellarTransaction,
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

    private func transaction(sendDetails: SendDetails) -> Single<StellarTransaction> {
        horizonProxy.accountResponse(for: sendDetails.fromAddress)
            .flatMap(weak: self) { (self, sourceAccount) -> Single<StellarTransaction> in
                guard sendDetails.value.currencyType == .coin(.stellar) else {
                    return .error(PlatformKitError.illegalArgument)
                }
                guard sendDetails.fee.currencyType == .coin(.stellar) else {
                    return .error(PlatformKitError.illegalArgument)
                }
                return self.createTransaction(sendDetails: sendDetails, sourceAccount: sourceAccount)
            }
    }

    private func createTransaction(
        sendDetails: SendDetails,
        sourceAccount: AccountResponse
    ) -> Single<StellarTransaction> {
        Single
            .zip(operation(sendDetails: sendDetails), sendTimeOutSeconds)
            .map { operation, sendTimeOutSeconds -> StellarTransaction in
                var timebounds: TimeBounds?
                let expirationDate = Calendar.current.date(
                    byAdding: .second,
                    value: sendTimeOutSeconds,
                    to: Date()
                )
                if let expirationDate = expirationDate?.timeIntervalSince1970 {
                    timebounds = try? TimeBounds(
                        minTime: 0,
                        maxTime: UInt64(expirationDate)
                    )
                }
                let transaction = try StellarTransaction(
                    sourceAccount: sourceAccount,
                    operations: [operation],
                    memo: sendDetails.horizonMemo,
                    timeBounds: timebounds,
                    maxOperationFee: UInt32(sendDetails.fee.minorString)!
                )
                return transaction
            }
    }

    /// Returns the appropriate operation depending if the destination account already exists or not.
    private func operation(sendDetails: SendDetails) -> Single<stellarsdk.Operation> {
        horizonProxy.accountResponse(for: sendDetails.toAddress)
            .map { response -> stellarsdk.Operation in
                try stellarsdk.PaymentOperation(
                    sourceAccountId: sendDetails.fromAddress,
                    destinationAccountId: response.accountId,
                    asset: stellarsdk.Asset(type: stellarsdk.AssetType.ASSET_TYPE_NATIVE)!,
                    amount: sendDetails.value.displayMajorValue
                )
            }
            .catchError { error -> Single<stellarsdk.Operation> in
                // Build operation
                switch error {
                case StellarAccountError.noDefaultAccount:
                    let destination = try KeyPair(accountId: sendDetails.toAddress)
                    let createAccountOperation = stellarsdk.CreateAccountOperation(
                        sourceAccountId: sendDetails.fromAddress,
                        destination: destination,
                        startBalance: sendDetails.value.displayMajorValue
                    )
                    return .just(createAccountOperation)
                default:
                    throw error
                }
            }
    }
}

extension stellarsdk.TransactionPostResponseEnum {
    fileprivate func toSendConfirmationDetails(sendDetails: SendDetails) throws -> SendConfirmationDetails {
        switch self {
        case .success(let details):
            let feeCharged = CryptoValue(
                amount: BigInt(details.transactionResult.feeCharged),
                currency: .coin(.stellar)
            )
            return SendConfirmationDetails(
                sendDetails: sendDetails,
                fees: feeCharged,
                transactionHash: details.transactionHash
            )
        case .destinationRequiresMemo:
            throw StellarNetworkError.unknown
        case .failure(let error):
            throw error.toStellarServiceError()
        }
    }
}

extension SendDetails {
    fileprivate var horizonMemo: stellarsdk.Memo {
        switch memo {
        case nil:
            return .none
        case .id(let id):
            return .id(id)
        case .text(let text):
            return .text(text)
        }
    }
}
