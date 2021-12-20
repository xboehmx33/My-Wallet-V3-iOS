// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComposableArchitecture
import ComposableNavigation
import FeatureInterestDomain
import Localization
import MoneyKit
import PlatformKit
import PlatformUIKit
import SwiftUI
import ToolKit
import UIComponentsKit

protocol InterestAccountListViewDelegate: AnyObject {
    func didTapVerifyMyIdentity()
    func didTapBuyCrypto(_ cryptoCurrency: CryptoCurrency)
}

struct InterestAccountListView: View {

    private typealias LocalizationId = LocalizationConstants.Interest.Screen.Overview

    weak var delegate: InterestAccountListViewDelegate?

    let store: Store<InterestAccountListState, InterestAccountListAction>

    var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                if viewStore.isLoading {
                    LoadingStateView(title: "")
                        .onAppear {
                            if let cryptoCurrency = viewStore.buyCryptoCurrency {
                                delegate?.didTapBuyCrypto(cryptoCurrency)
                            }
                        }
                } else if viewStore.interestAccountFetchFailed {
                    InterestAccountListErrorView(action: {
                        viewStore.send(.setupInterestAccountListScreen)
                    })
                } else {
                    NavigationView {
                        List {
                            if !viewStore.isKYCVerified {
                                InterestIdentityVerificationView {
                                    delegate?.didTapVerifyMyIdentity()
                                }
                                .listRowInsets(EdgeInsets())
                            }
                            ForEachStore(
                                store.scope(
                                    state: \.interestAccountDetails,
                                    action: InterestAccountListAction.interestAccountButtonTapped
                                )
                            ) { cellStore in
                                InterestAccountListItem(store: cellStore)
                            }
                        }
                        .whiteNavigationBarStyle()
                        .listStyle(PlainListStyle())
                        .navigationTitle(LocalizationId.title)
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationRoute(in: store)
                    }
                }
            }
            .onAppear {
                viewStore.send(.setupInterestAccountListScreen)
            }
        }
    }
}

struct InterestAccountListView_Previews: PreviewProvider {

    static var testCurrencyPairs = [
        InterestAccountDetails(
            ineligibilityReason: .eligible,
            currency: .crypto(.coin(.bitcoin)),
            balance: MoneyValue.create(major: "12.0", currency: .crypto(.coin(.bitcoin)))!,
            interestEarned: MoneyValue.create(major: "12.0", currency: .crypto(.coin(.bitcoin)))!,
            rate: 8.0
        )
    ]

    static var previews: some View {
        InterestAccountListView(
            store: .init(
                initialState: InterestAccountListState(
                    interestAccountDetails: .init(uniqueElements: testCurrencyPairs),
                    loadingStatus: .loaded
                ),
                reducer: interestAccountListReducer,
                environment: .init(
                    fiatCurrencyService: NoOpFiatCurrencyPublisher(),
                    accountOverviewRepository: NoOpInterestAccountOverviewRepository(),
                    accountBalanceRepository: NoOpInterestAccountBalanceRepository(),
                    accountRepository: NoOpBlockchainAccountRepository(),
                    priceService: NoOpPriceService(),
                    blockchainAccountRepository: NoOpBlockchainAccountRepository(),
                    kycVerificationService: NoOpKYCVerificationService(),
                    transactionRouterAPI: NoOpTransactionsRouter(),
                    mainQueue: .main
                )
            )
        )
    }
}
