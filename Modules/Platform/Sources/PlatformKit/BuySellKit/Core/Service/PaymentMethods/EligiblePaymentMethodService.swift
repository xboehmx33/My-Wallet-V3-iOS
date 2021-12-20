// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import MoneyKit
import RxRelay
import RxSwift
import ToolKit

final class EligiblePaymentMethodsService: PaymentMethodsServiceAPI {

    // MARK: - Public properties

    let paymentMethods: Observable<[PaymentMethod]>

    let paymentMethodsSingle: Single<[PaymentMethod]>

    let supportedCardTypes: Single<Set<CardType>>

    // MARK: - Private properties

    private let refreshAction = PublishRelay<Void>()

    private let eligibleMethodsClient: PaymentEligibleMethodsClientAPI
    private let tiersService: KYCTiersServiceAPI
    private let fiatCurrencyService: FiatCurrencySettingsServiceAPI
    private let enabledCurrenciesService: EnabledCurrenciesServiceAPI

    // MARK: - Setup

    init(
        eligibleMethodsClient: PaymentEligibleMethodsClientAPI = resolve(),
        tiersService: KYCTiersServiceAPI = resolve(),
        reactiveWallet: ReactiveWalletAPI = resolve(),
        enabledCurrenciesService: EnabledCurrenciesServiceAPI = resolve(),
        fiatCurrencyService: FiatCurrencySettingsServiceAPI = resolve()
    ) {
        self.eligibleMethodsClient = eligibleMethodsClient
        self.tiersService = tiersService
        self.fiatCurrencyService = fiatCurrencyService
        self.enabledCurrenciesService = enabledCurrenciesService

        let enabledFiatCurrencies = enabledCurrenciesService.allEnabledFiatCurrencies
        let fetch = fiatCurrencyService.tradingCurrencyPublisher
            .asObservable()
            .flatMap { [tiersService, eligibleMethodsClient] fiatCurrency -> Observable<[PaymentMethod]> in
                let fetchTiers = tiersService.fetchTiers().asSingle()
                return fetchTiers.flatMap { tiersResult -> Single<(KYC.UserTiers, SimplifiedDueDiligenceResponse)> in
                    tiersService.simplifiedDueDiligenceEligibility(for: tiersResult.latestApprovedTier)
                        .asObservable()
                        .asSingle()
                        .map { sddEligibiliy in (tiersResult, sddEligibiliy) }
                }
                .flatMap { tiersResult, sddEligility -> Single<([PaymentMethodsResponse.Method], Bool)> in
                    eligibleMethodsClient.eligiblePaymentMethods(
                        for: fiatCurrency.code,
                        currentTier: tiersResult.latestApprovedTier,
                        sddEligibleTier: ( // get SDD limits for eligible users
                            (tiersResult.isTier0 || tiersResult.isTier1Approved) && sddEligility.eligible
                        ) ? sddEligility.tier : nil
                    )
                    .map { ($0, sddEligility.eligible) }
                    .asSingle()
                }
                .map { methods, sddEligible -> [PaymentMethod] in
                    let paymentMethods: [PaymentMethod] = .init(
                        methods: methods,
                        currency: fiatCurrency,
                        supportedFiatCurrencies: enabledFiatCurrencies
                    )
                    guard sddEligible else {
                        return paymentMethods
                    }
                    // only visible payment methods should be shown to the user
                    return paymentMethods.filter(\.isVisible)
                }
                .map { paymentMethods in
                    paymentMethods.filter { paymentMethod in
                        switch paymentMethod.type {
                        case .card,
                             .bankTransfer:
                            return true
                        case .funds(let currencyType):
                            return currencyType.code == fiatCurrency.code
                        case .bankAccount:
                            // Filter out bank transfer details from currencies we do not
                            //  have local support/UI.
                            return enabledFiatCurrencies.contains(paymentMethod.min.currency)
                        }
                    }
                }
                .asObservable()
            }
            .distinctUntilChanged()
            .share(replay: 1, scope: .whileConnected)

        paymentMethods = refreshAction
            .startWith(())
            .asObservable()
            .flatMapLatest { _ -> Observable<[PaymentMethod]> in
                fetch
            }
            .share(replay: 1, scope: .whileConnected)

        paymentMethodsSingle = fetch
            .take(1)
            .asSingle()

        supportedCardTypes = fetch
            .take(1)
            .asSingle()
            .map { paymentMethods in
                guard let card = paymentMethods.first(where: { $0.type.isCard }) else {
                    return []
                }
                switch card.type {
                case .card(let types):
                    return types
                case .bankAccount, .bankTransfer, .funds:
                    return []
                }
            }
    }

    func supportedPaymentMethods(
        for currency: FiatCurrency
    ) -> Single<[PaymentMethod]> {
        let enabledFiatCurrencies = enabledCurrenciesService.allEnabledFiatCurrencies
        return Single
            .just(currency)
            .flatMap { [tiersService, eligibleMethodsClient] fiatCurrency -> Single<[PaymentMethod]> in
                let fetchTiers = tiersService.fetchTiers().asSingle()
                return fetchTiers.flatMap { tiersResult -> Single<(KYC.UserTiers, SimplifiedDueDiligenceResponse)> in
                    tiersService.simplifiedDueDiligenceEligibility(for: tiersResult.latestApprovedTier)
                        .asSingle()
                        .map { sddEligibiliy in (tiersResult, sddEligibiliy) }
                }
                .flatMap { tiersResult, sddEligility -> Single<([PaymentMethodsResponse.Method], Bool)> in
                    eligibleMethodsClient.eligiblePaymentMethods(
                        for: fiatCurrency.code,
                        currentTier: tiersResult.latestApprovedTier,
                        sddEligibleTier: ( // get SDD limits for eligible users
                            (tiersResult.isTier0 || tiersResult.isTier1Approved) && sddEligility.eligible
                        ) ? sddEligility.tier : nil
                    )
                    .map { ($0, sddEligility.eligible) }
                    .asSingle()
                }
                .map { methods, sddEligible -> [PaymentMethod] in
                    let paymentMethods: [PaymentMethod] = .init(
                        methods: methods,
                        currency: fiatCurrency,
                        supportedFiatCurrencies: enabledFiatCurrencies
                    )
                    guard sddEligible else {
                        return paymentMethods
                    }
                    // only visible payment methods should be shown to the user
                    return paymentMethods.filter(\.isVisible)
                }
                .map { paymentMethods in
                    paymentMethods.filter { paymentMethod in
                        switch paymentMethod.type {
                        case .card,
                             .bankTransfer:
                            return true
                        case .funds(let currencyType):
                            return currencyType.code == fiatCurrency.code
                        case .bankAccount:
                            // Filter out bank transfer details from currencies we do not
                            //  have local support/UI.
                            return enabledFiatCurrencies.contains(paymentMethod.min.currency)
                        }
                    }
                }
            }
    }

    func refresh() {
        DispatchQueue.main.async { [weak self] in
            self?.refreshAction.accept(())
        }
    }
}
