// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
import RxSwift

public enum TransactionResult {
    case signed(rawTx: String)
    case hashed(txHash: String, amount: MoneyValue?, order: OrderDetails? = nil)
    case unHashed(amount: MoneyValue)
}

public protocol TransactionTarget: Account {

    typealias TxCompleted = (TransactionResult) -> Completable

    /// onTxCompleted should be used by CryptoInterestAccount and CustodialTradingAccount,
    /// it should POST to "payments/deposits/pending", check Android
    var onTxCompleted: TxCompleted { get }
}

extension TransactionTarget {
    public var onTxCompleted: TxCompleted {
        { _ in Completable.empty() }
    }
}

public protocol CryptoTarget: TransactionTarget {
    var asset: CryptoCurrency { get }
}

extension CryptoTarget {

    public var currencyType: CurrencyType {
        asset.currencyType
    }
}

/// A TransactionTarget that disallows changing its details (e.g. amount, target)
///
/// Currently used when dealing with BitPay, or WalletConnect transactions.
public protocol StaticTransactionTarget: TransactionTarget {}

/// A TransactionTarget that wraps an opaque transaction object.
/// This means we can't read each individual detail (e.g. amount, target).
///
/// Currently used when dealing with one WalletConnect method but it may be used elsewhere when the wallet receives a
/// transaction already signed/encoded and must just push it to the network.
public protocol RawStaticTransactionTarget: StaticTransactionTarget {}

/// A Wallet Connect Transaction Target.
public protocol WalletConnectTarget: StaticTransactionTarget {}
