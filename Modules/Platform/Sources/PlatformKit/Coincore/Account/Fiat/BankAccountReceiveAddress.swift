// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation
import MoneyKit

public final class BankAccountReceiveAddress: ReceiveAddress {
    public let address: String
    public let label: String
    public let currencyType: CurrencyType

    public init(address: String, label: String, currencyType: CurrencyType) {
        self.address = address
        self.label = label
        self.currencyType = currencyType
    }
}
