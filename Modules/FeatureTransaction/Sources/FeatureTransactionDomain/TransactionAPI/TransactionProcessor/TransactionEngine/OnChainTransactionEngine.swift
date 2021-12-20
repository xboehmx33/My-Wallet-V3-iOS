// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
import PlatformKit
import RxSwift

public protocol OnChainTransactionEngine: TransactionEngine {}

extension OnChainTransactionEngine {

    public var sourceCryptoAccount: CryptoAccount {
        sourceAccount as! CryptoAccount
    }

    public var availableBalance: Single<MoneyValue> {
        sourceAccount
            .actionableBalance
    }

    /// A default implementation for `assertInputsValid()` that validates that `transactionTarget`
    /// is a `CryptoReceiveAddress` and that its address isn't empty, and that the source account and
    /// target account have the same asset.
    public func defaultAssertInputsValid() {
        guard let target = transactionTarget as? CryptoReceiveAddress else {
            preconditionFailure("\(String(describing: transactionTarget)) is not CryptoReceiveAddress")
        }
        precondition(!target.address.isEmpty)
        precondition(sourceCryptoAccount.asset == target.asset)
    }

    public func doUpdateFeeLevel(pendingTransaction: PendingTransaction, level: FeeLevel, customFeeAmount: MoneyValue) -> Single<PendingTransaction> {
        precondition(pendingTransaction.feeSelection.availableLevels.contains(level))
        if pendingTransaction.hasFeeLevelChanged(newLevel: level, newAmount: customFeeAmount) {
            return updateFeeSelection(
                pendingTransaction: pendingTransaction,
                newFeeLevel: level,
                customFeeAmount: customFeeAmount
            )
        } else {
            return .just(pendingTransaction)
        }
    }

    public func updateFeeSelection(
        pendingTransaction: PendingTransaction,
        newFeeLevel: FeeLevel,
        customFeeAmount: MoneyValue?
    ) -> Single<PendingTransaction> {
        // TODO: Store default fee level
        let pendingTransaction = pendingTransaction
            .update(selectedFeeLevel: newFeeLevel, customFeeAmount: customFeeAmount)

        return update(amount: pendingTransaction.amount, pendingTransaction: pendingTransaction)
            .flatMap(weak: self) { (self, updatedTransaction) -> Single<PendingTransaction> in
                self.validateAmount(pendingTransaction: updatedTransaction)
            }
            .flatMap(weak: self) { (self, validatedTransaction) -> Single<PendingTransaction> in
                self.doBuildConfirmations(pendingTransaction: validatedTransaction)
            }
    }

    public func getFeeState(
        pendingTransaction: PendingTransaction,
        feeOptions: FeeOptions? = nil
    ) -> Single<FeeState> {
        do {
            return .just(
                try getFeeState(
                    pendingTransaction: pendingTransaction,
                    feeOptions: feeOptions
                )
            )
        } catch {
            return .error(error)
        }
    }

    public func getFeeState(
        pendingTransaction: PendingTransaction,
        feeOptions: FeeOptions? = nil
    ) throws -> FeeState {
        switch (pendingTransaction.feeLevel, pendingTransaction.customFeeAmount) {
        case (.custom, nil):
            return .validCustomFee
        case (.custom, .some(let amount)):
            let currency = pendingTransaction.amount.currency
            let zero: MoneyValue = .zero(currency: currency)
            let minimum = MoneyValue.create(minor: 1, currency: pendingTransaction.amount.currency)

            switch amount {
            case _ where try amount < minimum:
                return FeeState.feeUnderMinLimit
            case _ where try amount >= minimum && amount <= (feeOptions?.minLimit ?? zero):
                return .feeUnderRecommended
            case _ where try amount >= (feeOptions?.maxLimit ?? zero):
                return .feeOverRecommended
            default:
                return .validCustomFee
            }
        default:
            if try pendingTransaction.available < pendingTransaction.amount {
                return .feeTooHigh
            }
            return .valid(absoluteFee: pendingTransaction.feeAmount)
        }
    }
}

// TODO: Revisit
public struct FeeOptions {
    var minLimit: MoneyValue
    var maxLimit: MoneyValue
}
