// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation
import MoneyKit
import RxSwift

/// Each asset class may have its own reason as to why a proposed transaction
/// is invalid. Insufficient funds would be an example of one that is applicable to
/// pretty much every asset class but, in cases like ETH you may have a pending transaction
/// that hasn't confirmed yet.
public protocol TransactionValidationError: Error {}

public enum PlatformKitTransactionValidationError: TransactionValidationError {
    case `default`
}

public enum TransactionValidationResult {
    /// The amount you would like to send is valid
    case ok
    /// The amount you would like to send is invalid
    case invalid(TransactionValidationError)

    /// Returns the error in case of `.invalid`
    public var error: TransactionValidationError? {
        switch self {
        case .invalid(let error):
            return error
        case .ok:
            return nil
        }
    }

    /// Returns `true` in case of `.ok`
    public var isOk: Bool {
        switch self {
        case .ok:
            return true
        case .invalid:
            return false
        }
    }
}

/// `ValidateTransactionAPI` takes a `CryptoMoney`. The reason that this is not a `CryptoValue` is `ERC20TokenValue`
/// and `EthereumValue` are not `CryptoValues` though they do conform to `CryptoMoney`. Use this API to confirm
/// that an amount you would like to send is valid.
public protocol ValidateTransactionAPI {
    func validateCryptoAmount(amount: CryptoMoney) -> Single<TransactionValidationResult>
}
