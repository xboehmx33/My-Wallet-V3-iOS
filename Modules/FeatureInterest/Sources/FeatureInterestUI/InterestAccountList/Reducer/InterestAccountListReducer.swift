// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import ComposableArchitecture
import FeatureInterestDomain
import PlatformKit
import ToolKit

struct TransactionFetchIdentifier: Hashable {}

typealias InterestAccountListReducer = Reducer<
    InterestAccountListState,
    InterestAccountListAction,
    InterestAccountSelectionEnvironment
>

let interestAccountListReducer = Reducer.combine(
    interestNoEligibleWalletsReducer
        .optional()
        .pullback(
            state: \.interestNoEligibleWalletsState,
            action: /InterestAccountListAction.interestAccountNoEligibleWallets,
            environment: { _ in .init() }
        ),
    interestAccountDetailsReducer
        .optional()
        .pullback(
            state: \.interestAccountDetailsState,
            action: /InterestAccountListAction.interestAccountDetails,
            environment: {
                InterestAccountDetailsEnvironment(
                    fiatCurrencyService: $0.fiatCurrencyService,
                    blockchainAccountRepository: $0.blockchainAccountRepository,
                    priceService: $0.priceService,
                    mainQueue: $0.mainQueue
                )
            }
        ),
    Reducer<
        InterestAccountListState,
        InterestAccountListAction,
        InterestAccountSelectionEnvironment
    > { state, action, environment in
        switch action {
        case .didReceiveInterestAccountResponse(let response):
            switch response {
            case .success(let accountOverviews):
                let details: [InterestAccountDetails] = accountOverviews.map { accountOverview in
                    .init(
                        ineligibilityReason: accountOverview.ineligibilityReason,
                        currency: accountOverview.currency,
                        balance: accountOverview.balance,
                        interestEarned: accountOverview.totalEarned,
                        rate: accountOverview.interestAccountRate.rate
                    )
                }
                .sorted { $0.balance.isPositive && !$1.balance.isPositive }

                state.interestAccountOverviews = accountOverviews
                state.interestAccountDetails = .init(uniqueElements: details)
                state.loadingStatus = .loaded
            case .failure(let error):
                state.loadingStatus = .loaded
                Logger.shared.error(error)
            }
            return .none

        case .setupInterestAccountListScreen:
            state.loadingStatus = .fetchingAccountStatus
            return environment
                .kycVerificationService
                .isKYCVerified
                .receive(on: environment.mainQueue)
                .eraseToEffect()
                .map { result in
                    .didReceiveKYCVerificationResponse(result)
                }
        case .didReceiveKYCVerificationResponse(let value):
            state.isKYCVerified = value
            return Effect(value: .loadInterestAccounts)
        case .loadInterestAccounts:
            state.loadingStatus = .fetchingRewardsAccounts
            return environment
                .fiatCurrencyService
                .displayCurrencyPublisher
                .flatMap { [environment] fiatCurrency in
                    environment
                        .accountOverviewRepository
                        .fetchInterestAccountOverviewListForFiatCurrency(fiatCurrency)
                }
                .receive(on: environment.mainQueue)
                .catchToEffect()
                .map { result in
                    .didReceiveInterestAccountResponse(result)
                }

        case .interestAccountButtonTapped(let selected, let action):
            switch action {
            case .viewInterestButtonTapped:
                guard let overview = state
                    .interestAccountOverviews
                    .first(where: { $0.id == selected.identity })
                else {
                    fatalError("Expected an InterestAccountOverview")
                }

                state.interestAccountDetailsState = .init(interestAccountOverview: overview)
                return .enter(into: .details, context: .none)
            case .earnInterestButtonTapped(let value):
                let blockchainAccountRepository = environment.blockchainAccountRepository
                let currency = value.currency

                return blockchainAccountRepository
                    .accountWithCurrencyType(
                        currency,
                        accountType: .custodial(.savings)
                    )
                    .compactMap { $0 as? CryptoInterestAccount }
                    .flatMap { account -> AnyPublisher<(Bool, InterestTransactionState), Never> in
                        let availableAccounts = blockchainAccountRepository
                            .accountsAvailableToPerformAction(
                                .interestTransfer,
                                target: account
                            )
                            .map { $0.filter { $0.currencyType == account.currencyType } }
                            .map { !$0.isEmpty }
                            .replaceError(with: false)
                            .eraseToAnyPublisher()

                        let interestTransactionState = InterestTransactionState(
                            account: account,
                            action: .interestTransfer
                        )

                        return Publishers.Zip(
                            availableAccounts,
                            Just(interestTransactionState)
                        )
                        .eraseToAnyPublisher()
                    }
                    .receive(on: environment.mainQueue)
                    .catchToEffect()
                    .map { values -> InterestAccountListAction in
                        guard let (areAccountsAvailable, transactionState) = values.successData else {
                            impossible()
                        }
                        if areAccountsAvailable {
                            return .interestTransactionStateFetched(transactionState)
                        }

                        let ineligibleWalletsState = InterestNoEligibleWalletsState(
                            interestAccountRate: InterestAccountRate(
                                currencyCode: currency.code,
                                rate: value.rate
                            )
                        )
                        return .interestAccountIsWithoutEligibleWallets(ineligibleWalletsState)
                    }
            }
        case .interestAccountIsWithoutEligibleWallets(let ineligibleWalletsState):
            state.interestNoEligibleWalletsState = ineligibleWalletsState
            return .enter(into: .noWalletsError)
        case .interestAccountNoEligibleWallets(let action):
            switch action {
            case .startBuyTapped:
                return .none
            case .dismissNoEligibleWalletsScreen:
                return .dismiss()
            case .startBuyAfterDismissal(let cryptoCurrency):
                state.loadingStatus = .fetchingRewardsAccounts
                return Effect(value: .dismissAndLaunchBuy(cryptoCurrency))
            case .startBuyOnDismissalIfNeeded:
                return .none
            }
        case .dismissAndLaunchBuy(let cryptoCurrency):
            state.buyCryptoCurrency = cryptoCurrency
            return .none
        case .interestTransactionStateFetched(let transactionState):
            state.interestTransactionState = transactionState
            let isTransfer = transactionState.action == .interestTransfer
            return Effect(
                value:
                isTransfer ? .startInterestTransfer(transactionState) : .startInterestWithdraw(transactionState)
            )
        case .startInterestWithdraw(let value):
            return environment
                .transactionRouterAPI
                .presentTransactionFlow(to: .interestWithdraw(value.account))
                .catchToEffect()
                .map { _ -> InterestAccountListAction in
                    .loadInterestAccounts
                }
        case .startInterestTransfer(let value):
            return environment
                .transactionRouterAPI
                .presentTransactionFlow(to: .interestTransfer(value.account))
                .catchToEffect()
                .map { _ -> InterestAccountListAction in
                    .loadInterestAccounts
                }
        case .route(let route):
            state.route = route
            return .none
        case .interestAccountDetails:
            return .none
        }
    },
    interestReducerCore
)

let interestReducerCore = Reducer<
    InterestAccountListState,
    InterestAccountListAction,
    InterestAccountSelectionEnvironment
> { _, action, environment in
    switch action {
    case .interestAccountDetails(.dismissInterestDetailsScreen):
        return .dismiss()
    case .interestAccountDetails(.loadCryptoInterestAccount(isTransfer: let isTransfer, let currency)):
        return environment
            .blockchainAccountRepository
            .accountWithCurrencyType(
                currency,
                accountType: .custodial(.savings)
            )
            .compactMap { $0 as? CryptoInterestAccount }
            .map { account in
                InterestTransactionState(
                    account: account,
                    action: isTransfer ? .interestTransfer : .interestWithdraw
                )
            }
            .catchToEffect()
            .map { transactionState in
                guard let value = transactionState.successData else {
                    unimplemented()
                }
                return value
            }
            .map { transactionState -> InterestAccountListAction in
                .interestTransactionStateFetched(transactionState)
            }
    default:
        return .none
    }
}
