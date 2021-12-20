// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import PlatformKit
import RxSwift
import ToolKit

extension CoincoreAPI {

    public func createTransactionProcessor(
        with account: BlockchainAccount,
        target: TransactionTarget,
        action: AssetAction
    ) -> Single<TransactionProcessor> {
        switch account {
        case is CryptoNonCustodialAccount:
            return createOnChainProcessor(
                with: account as! CryptoNonCustodialAccount,
                target: target,
                action: action
            )
        case is CryptoInterestAccount:
            return createInterestWithdrawTradingProcessor(
                with: account as! CryptoInterestAccount,
                target: target,
                action: action
            )
        case is CryptoTradingAccount:
            return createTradingProcessor(
                with: account as! CryptoTradingAccount,
                target: target,
                action: action
            )
        case is BankAccount where action == .deposit:
            return createFiatDepositProcessor(
                with: account as! LinkedBankAccount,
                target: target
            )
        case is FiatAccount where action == .buy:
            return createBuyProcessor(
                with: account,
                destination: target
            )
        case is FiatAccount where action == .withdraw:
            return createFiatWithdrawalProcessor(
                with: account as! FiatAccount,
                target: target
            )
        default:
            impossible()
        }
    }

    private func createOnChainProcessor(
        with account: CryptoNonCustodialAccount,
        target: TransactionTarget,
        action: AssetAction
    ) -> Single<TransactionProcessor> {
        let factory = account.createTransactionEngine() as! OnChainTransactionEngineFactory
        let interestOnChainFactory: InterestOnChainTransactionEngineFactoryAPI = resolve()
        switch (target, action) {
        case (is CryptoInterestAccount, .interestTransfer):
            guard let target = target as? CryptoInterestAccount else {
                impossible()
            }

            return target
                .receiveAddress
                .flatMap { receiveAddress in
                    account
                        .requireSecondPassword
                        .map { requiresSecondPassword -> TransactionProcessor in
                            .init(
                                sourceAccount: account,
                                transactionTarget: receiveAddress,
                                engine: interestOnChainFactory
                                    .build(
                                        requiresSecondPassword: requiresSecondPassword,
                                        action: .interestTransfer,
                                        onChainEngine: factory.build(
                                            requiresSecondPassword: requiresSecondPassword
                                        )
                                    )
                            )
                        }
                }
        case (is WalletConnectTarget, _):
            return account
                .requireSecondPassword
                .map { _ -> TransactionProcessor in
                    let walletConnectEngineFactory: WalletConnectEngineFactoryAPI = resolve()
                    return .init(
                        sourceAccount: account,
                        transactionTarget: target,
                        engine: walletConnectEngineFactory.build(
                            target: target
                        )
                    )
                }
        case (is BitPayInvoiceTarget, .send):
            return account
                .requireSecondPassword
                .map { requiresSecondPassword -> TransactionProcessor in
                    .init(
                        sourceAccount: account,
                        transactionTarget: target,
                        engine: BitPayTransactionEngine(
                            onChainEngine: factory.build(requiresSecondPassword: requiresSecondPassword)
                        )
                    )
                }
        case (is CryptoAccount, .swap):
            return account
                .requireSecondPassword
                .map { requiresSecondPassword -> TransactionProcessor in
                    .init(
                        sourceAccount: account,
                        transactionTarget: target,
                        engine: OnChainSwapTransactionEngine(
                            quotesEngine: SwapQuotesEngine(),
                            requireSecondPassword: requiresSecondPassword,
                            onChainEngine: factory.build(requiresSecondPassword: requiresSecondPassword)
                        )
                    )
                }
        case (is CryptoReceiveAddress, .send):
            // `Target` must be a `CryptoReceiveAddress`
            guard let receiveAddress = target as? CryptoReceiveAddress else {
                fatalError("Expected a receiveAddress: \(target)")
            }
            return account
                .requireSecondPassword
                .map { requiresSecondPassword -> TransactionProcessor in
                    .init(
                        sourceAccount: account,
                        transactionTarget: receiveAddress,
                        engine: factory.build(requiresSecondPassword: requiresSecondPassword)
                    )
                }

        case (is CryptoAccount, .send):
            // `Target` must be a `CryptoReceiveAddress`
            guard let destination = target as? SingleAccount else {
                fatalError("Expected a SingleAccount: \(target)")
            }
            let data = Single.zip(
                destination.receiveAddress,
                account.requireSecondPassword
            )
            return data
                .map { values -> TransactionProcessor in
                    let (receiveAddress, requiresSecondPassword) = values
                    return .init(
                        sourceAccount: account,
                        transactionTarget: receiveAddress,
                        engine: factory.build(requiresSecondPassword: requiresSecondPassword)
                    )
                }
        case (_, .sell):
            return account
                .requireSecondPassword
                .map { requiresSecondPassword -> TransactionProcessor in
                    .init(
                        sourceAccount: account,
                        transactionTarget: target,
                        engine: NonCustodialSellTransactionEngine(
                            quotesEngine: SwapQuotesEngine(),
                            requireSecondPassword: requiresSecondPassword,
                            onChainEngine: factory.build(requiresSecondPassword: requiresSecondPassword)
                        )
                    )
                }
        default:
            unimplemented()
        }
    }

    private func createTradingProcessor(
        with account: CryptoTradingAccount,
        target: TransactionTarget,
        action: AssetAction
    ) -> Single<TransactionProcessor> {
        switch action {
        case .swap:
            return createTradingProcessorSwap(with: account, target: target)
        case .send:
            return createTradingProcessorSend(with: account, target: target)
        case .buy:
            unimplemented("This should not be needed as the Buy engine should process the transaction")
        case .sell:
            return createTradingProcessorSell(with: account, target: target)
        case .interestTransfer:
            return createInterestTransferTradingProcessor(with: account, target: target)
        case .deposit,
             .receive,
             .sign,
             .viewActivity,
             .withdraw,
             .interestWithdraw:
            unimplemented()
        }
    }

    private func createBuyProcessor(
        with source: BlockchainAccount,
        destination: TransactionTarget
    ) -> Single<TransactionProcessor> {
        .just(
            TransactionProcessor(
                sourceAccount: source,
                transactionTarget: destination,
                engine: BuyTransactionEngine()
            )
        )
    }

    private func createFiatWithdrawalProcessor(
        with account: FiatAccount,
        target: TransactionTarget
    ) -> Single<TransactionProcessor> {
        Single.just(
            TransactionProcessor(
                sourceAccount: account,
                transactionTarget: target,
                engine: FiatWithdrawalTransactionEngine()
            )
        )
    }

    private func createFiatDepositProcessor(
        with account: LinkedBankAccount,
        target: TransactionTarget
    ) -> Single<TransactionProcessor> {
        Single.just(
            TransactionProcessor(
                sourceAccount: account,
                transactionTarget: target,
                engine: FiatDepositTransactionEngine()
            )
        )
    }

    private func createTradingProcessorSwap(
        with account: CryptoTradingAccount,
        target: TransactionTarget
    ) -> Single<TransactionProcessor> {
        Single.just(
            TransactionProcessor(
                sourceAccount: account,
                transactionTarget: target as! CryptoTradingAccount,
                engine: TradingToTradingSwapTransactionEngine(
                    quotesEngine: SwapQuotesEngine()
                )
            )
        )
    }

    private func createInterestTransferTradingProcessor(
        with account: CryptoTradingAccount,
        target: TransactionTarget
    ) -> Single<TransactionProcessor> {
        guard target is CryptoInterestAccount else {
            impossible()
        }
        let factory: InterestTradingTransactionEngineFactoryAPI = resolve()
        return .just(
            .init(
                sourceAccount: account,
                transactionTarget: target,
                engine: factory
                    .build(
                        requiresSecondPassword: false,
                        action: .interestTransfer
                    )
            )
        )
    }

    private func createInterestWithdrawTradingProcessor(
        with account: CryptoInterestAccount,
        target: TransactionTarget,
        action: AssetAction
    ) -> Single<TransactionProcessor> {
        let tradingFactory: InterestTradingTransactionEngineFactoryAPI = resolve()
        let onChainFactory: InterestOnChainTransactionEngineFactoryAPI = resolve()
        switch target {
        case is CryptoTradingAccount:
            return Single.just(
                TransactionProcessor(
                    sourceAccount: account,
                    transactionTarget: target,
                    engine: tradingFactory
                        .build(
                            requiresSecondPassword: false,
                            action: action
                        )
                )
            )
        case let nonCustodialAccount as CryptoNonCustodialAccount:
            let factory = nonCustodialAccount.createTransactionEngine() as! OnChainTransactionEngineFactory
            guard let target = target as? CryptoNonCustodialAccount else {
                impossible()
            }
            return target
                .receiveAddress
                .flatMap { receiveAddress in
                    account
                        .requireSecondPassword
                        .map { requiresSecondPassword in
                            TransactionProcessor(
                                sourceAccount: account,
                                transactionTarget: receiveAddress,
                                engine: onChainFactory
                                    .build(
                                        requiresSecondPassword: requiresSecondPassword,
                                        action: action,
                                        onChainEngine: factory
                                            .build(
                                                requiresSecondPassword: requiresSecondPassword
                                            )
                                    )
                            )
                        }
                }
        default:
            unimplemented()
        }
    }

    private func createTradingProcessorSend(
        with account: CryptoTradingAccount,
        target: TransactionTarget
    ) -> Single<TransactionProcessor> {
        let receiveAddressTarget: Single<ReceiveAddress>
        switch target {
        case is ReceiveAddress:
            receiveAddressTarget = .just(target as! ReceiveAddress)
        case is CryptoAccount:
            receiveAddressTarget = (target as! CryptoAccount).receiveAddress
        default:
            impossible()
        }
        return receiveAddressTarget
            .map { receiveAddress -> TransactionProcessor in
                TransactionProcessor(
                    sourceAccount: account,
                    transactionTarget: receiveAddress,
                    engine: TradingToOnChainTransactionEngine()
                )
            }
    }

    private func createTradingProcessorSell(
        with account: CryptoAccount,
        target: TransactionTarget
    ) -> Single<TransactionProcessor> {
        .just(
            TransactionProcessor(
                sourceAccount: account,
                transactionTarget: target as! FiatAccount,
                engine: TradingSellTransactionEngine(quotesEngine: SwapQuotesEngine())
            )
        )
    }
}
