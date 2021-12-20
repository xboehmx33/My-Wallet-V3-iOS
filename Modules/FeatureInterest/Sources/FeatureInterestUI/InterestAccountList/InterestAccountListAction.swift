// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComposableArchitecture
import ComposableNavigation
import FeatureInterestDomain
import MoneyKit
import PlatformKit

enum InterestAccountListAction: Equatable, NavigationAction {
    case didReceiveInterestAccountResponse(Result<[InterestAccountOverview], InterestAccountOverviewError>)
    case setupInterestAccountListScreen
    case loadInterestAccounts
    case didReceiveKYCVerificationResponse(Bool)
    case dismissAndLaunchBuy(CryptoCurrency)
    case interestAccountDetails(InterestAccountDetailsAction)
    case interestAccountIsWithoutEligibleWallets(InterestNoEligibleWalletsState)
    case interestTransactionStateFetched(InterestTransactionState)
    case startInterestTransfer(InterestTransactionState)
    case startInterestWithdraw(InterestTransactionState)
    case interestAccountButtonTapped(InterestAccountOverview.ID, InterestAccountListItemAction)
    case interestAccountNoEligibleWallets(InterestNoEligibleWalletsAction)
    case route(RouteIntent<InterestAccountListRoute>?)
}
