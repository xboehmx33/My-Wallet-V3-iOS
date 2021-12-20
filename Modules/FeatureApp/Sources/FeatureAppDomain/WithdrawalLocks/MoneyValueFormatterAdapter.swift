// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
import FeatureWithdrawalLocksData
import Foundation
import MoneyKit
import PlatformKit

final class MoneyValueFormatterAdapter: MoneyValueFormatterAPI {

    func formatMoney(amount: String, currency: String) -> String {
        FiatValue(amount: BigInt(stringLiteral: amount), currency: .init(code: currency)!).displayString
    }
}
