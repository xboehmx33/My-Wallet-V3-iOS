// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
import PlatformKit

enum InterestAccountDetailsAction: Equatable {
    case loadInterestAccountBalanceInfo
    case loadSupportedActions
    case interestAccountActionsFetched([AssetAction])
    case interestAccountFiatBalanceFetchFailed
    case interestAccountFiatBalanceFetched(MoneyValue)
    case interestTransferTapped(CurrencyType)
    case interestWithdrawTapped(CurrencyType)
    case loadCryptoInterestAccount(isTransfer: Bool = false, CurrencyType)
    case closeButtonTapped
    case dismissInterestDetailsScreen
    case interestAccountDescriptorTapped(
        id: InterestAccountOverviewRowItem.ID,
        action: InterestAccountDetailsRowAction
    )
}
