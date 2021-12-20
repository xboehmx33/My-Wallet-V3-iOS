// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
import PlatformKit

enum FeatureTransactionUIError: Error {
    case emptySourceExchangeRate
    case emptyDestinationExchangeRate
    case emptySourceDestinationExchangeRate
    case emptySourceAccount
    case emptyDestinationAccount
    case unexpectedDestinationAccountType
    case unexpectedMoneyValueType(MoneyValue)
    case unexpectedCurrencyType(CurrencyType)
}
