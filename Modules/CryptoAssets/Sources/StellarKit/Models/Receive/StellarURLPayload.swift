// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
import PlatformKit
import stellarsdk

struct StellarURLPayload: SEP7URI {

    private static let scheme: String = "web+stellar"

    let cryptoCurrency: CryptoCurrency = .coin(.stellar)
    let address: String
    let amount: String?
    let includeScheme: Bool = true
    let memo: String?

    var absoluteString: String {
        var amountInDecimal: Decimal?
        if let amount = amount {
            amountInDecimal = Decimal(string: amount)
        }
        return URIScheme().getPayOperationURI(accountID: address, amount: amountInDecimal, memo: memo)
    }

    init(address: String, amount: String?, memo: String?) {
        self.address = address
        self.amount = amount
        self.memo = memo
    }

    init?(url: URL) {
        // Scheme must 'be web+stellar'
        guard Self.scheme == url.scheme else {
            return nil
        }

        // Get query arguments after "web+stellar:pay?". We do not support actions other than 'pay'.
        guard let arguments = url.absoluteString.components(separatedBy: "\(Self.scheme):\(PayOperation)").last else {
            return nil
        }
        let queryArguments = arguments.queryArgs
        // We must have an destination
        guard let destination = queryArguments["\(PayOperationParams.destination)"] else {
            return nil
        }

        // Optionally retrieve payment amount.
        let amount: String? = queryArguments["\(PayOperationParams.amount)"]

        // Optionally retrieve memo if memo type is text.
        var memo: String?
        let memoType: String? = queryArguments["\(PayOperationParams.memo_type)"]
        if memoType == nil || memoType == "MEMO_TEXT" {
            memo = queryArguments["\(PayOperationParams.memo)"]
        }

        self.init(address: destination, amount: amount, memo: memo)
    }
}
