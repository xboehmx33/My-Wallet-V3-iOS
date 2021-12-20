// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import Combine
import DIKit
import MoneyKit
import NabuNetworkError
import RxSwift
import RxToolKit

/// A service API that aggregates card addition logic
public protocol CardUpdateServiceAPI: AnyObject {
    func add(card: CardData) -> Single<PartnerAuthorizationData>
}

public final class CardUpdateService: CardUpdateServiceAPI {

    // MARK: - Types

    public enum ServiceError: Error {
        case unknownPartner
    }

    private enum CardUpdateEvent: AnalyticsEvent {
        case sbAddCardFailure
        case sbCardActivationFailure
        case sbCardEverypayFailure(data: String)

        var name: String {
            switch self {
            case .sbAddCardFailure:
                return "sb_add_card_failure"
            case .sbCardActivationFailure:
                return "sb_card_activation_failure"
            case .sbCardEverypayFailure:
                return "sb_card_everypay_failure"
            }
        }

        var params: [String: String]? {
            switch self {
            case .sbCardEverypayFailure(data: let data):
                return ["data": data]
            default:
                return nil
            }
        }
    }

    // MARK: - Injected

    private let cardClient: CardClientAPI
    private let everyPayClient: EveryPayClientAPI
    private let dataRepository: DataRepositoryAPI
    private let fiatCurrencyService: FiatCurrencySettingsServiceAPI
    private let analyticsRecorder: AnalyticsEventRecorderAPI
    private let eligibleMethodsClient: PaymentEligibleMethodsClientAPI
    private let featureFlagsService: FeatureFlagsServiceAPI

    // MARK: - Setup

    init(
        dataRepository: DataRepositoryAPI = resolve(),
        cardClient: CardClientAPI = resolve(),
        everyPayClient: EveryPayClientAPI = resolve(),
        fiatCurrencyService: FiatCurrencySettingsServiceAPI = resolve(),
        analyticsRecorder: AnalyticsEventRecorderAPI = resolve(),
        eligibleMethodsClient: PaymentEligibleMethodsClientAPI = resolve(),
        featureFlagsService: FeatureFlagsServiceAPI = resolve()
    ) {
        self.dataRepository = dataRepository
        self.cardClient = cardClient
        self.everyPayClient = everyPayClient
        self.analyticsRecorder = analyticsRecorder
        self.fiatCurrencyService = fiatCurrencyService
        self.eligibleMethodsClient = eligibleMethodsClient
        self.featureFlagsService = featureFlagsService
    }

    // swiftlint:disable function_body_length
    public func add(card: CardData) -> Single<PartnerAuthorizationData> {

        // Get the user email
        let email = dataRepository
            .user
            .asSingle()
            .map(\.email.address)

        // Get eligible payment methods
        let cardAcquirerTokens = eligibleMethodsClient
            .paymentsCardAcquirers()
            .asSingle()
            .map { acquirers -> [Single<Result<CardTokenizationResponse, Error>>] in
                acquirers
                    .compactMap { acquirer -> Single<CardTokenizationResponse>? in
                        switch acquirer.cardAcquirerName {
                        case .checkout:
                            return CheckoutClient(acquirer.apiKey)
                                .tokenize(card, accounts: acquirer.cardAcquirerAccountCodes)
                                .asSingle()
                        case .stripe:
                            return StripeClient(acquirer.apiKey)
                                .tokenize(card, accounts: acquirer.cardAcquirerAccountCodes)
                                .asSingle()
                        case .unknown, .everyPay:
                            return nil
                        }
                    }
                    .map { token -> Single<Result<CardTokenizationResponse, Error>> in
                        token
                            .retry(3)
                            .timeout(.seconds(3), scheduler: MainScheduler.asyncInstance)
                            .mapToResult()
                    }
            }
            .flatMap(Single.zip)
            .map { responses -> [String: String] in
                responses
                    .compactMap { result -> [String: String]? in
                        switch result {
                        case .success(let tokenResponse):
                            return tokenResponse.params
                        case .failure:
                            return nil
                        }
                    }
                    .reduce(into: [String: String]()) {
                        $0.merge($1)
                    }
            }
            .catchAndReturn([:])

        let ffCardAcquirerTokens = featureFlagsService
            .isEnabled(.remote(.newCardAcquirers))
            .asSingle()
            .flatMap { enabled -> Single<[String: String]> in
                enabled ? cardAcquirerTokens : .just([:])
            }

        return Single.zip(
            fiatCurrencyService.tradingCurrency.asSingle(),
            email,
            ffCardAcquirerTokens
        )
        .map { currency, email, tokens -> (currency: Currency, email: String, tokens: [String: String]) in
            (currency: currency, email: email, tokens: tokens)
        }
        // 1. Add the card details via BE
        .flatMap(weak: self) { (self, payload) -> Single<CardPayload> in
            self.cardClient
                .add(
                    for: payload.currency.code,
                    email: payload.email,
                    billingAddress: card.billingAddress.requestPayload,
                    paymentMethodTokens: payload.tokens
                )
                .asSingle()
                .do(onError: { _ in
                    self.analyticsRecorder.record(event: CardUpdateEvent.sbAddCardFailure)
                })
        }

        // 2. Activate the card
        .flatMap(weak: self) { (self, payload) -> Single<(cardId: String, partner: ActivateCardResponse.Partner)> in
            self.cardClient.activateCard(
                by: payload.identifier,
                url: PartnerAuthorizationData.exitLink
            )
            .map {
                (cardId: payload.identifier, partner: $0)
            }
            .asSingle()
            .do(onError: { _ in
                self.analyticsRecorder.record(event: CardUpdateEvent.sbCardActivationFailure)
            })
        }
        // 3. Partner
        .flatMap(weak: self) { (self, payload) -> Single<PartnerAuthorizationData> in
            self
                .add(
                    card: card,
                    via: payload.partner
                )
                .map {
                    PartnerAuthorizationData(
                        state: $0,
                        paymentMethodId: payload.cardId
                    )
                }
        }
    }

    // MARK: - Partner Integration

    private func add(
        card: CardData,
        via partner: ActivateCardResponse.Partner
    ) -> Single<PartnerAuthorizationData.State> {
        switch partner {
        case .everypay(let data):
            return add(card: card, with: data)
        case .cardAcquirer(let acquirer):
            return add(card: card, via: acquirer)
        case .unknown:
            return .error(ServiceError.unknownPartner)
        }
    }

    /// Add through acquirers
    private func add(
        card: CardData,
        via acquirer: ActivateCardResponse.CardAcquirer
    ) -> Single<PartnerAuthorizationData.State> {
        switch acquirer.cardAcquirerName {
        case .checkout:
            return .just(CheckoutClient.authorizationState(acquirer))
        case .everyPay:
            guard let apiUsername = acquirer.apiUserID,
                  let mobileToken = acquirer.apiToken,
                  let paymentLink = acquirer.paymentLink
            else {
                return Single.error(CardAcquirerError.missingParameters)
            }
            return add(card: card, with: .init(
                apiUsername: apiUsername,
                mobileToken: mobileToken,
                paymentLink: paymentLink,
                paymentState: acquirer.paymentState.rawValue
            ))
        case .stripe:
            return .just(StripeClient.authorizationState(acquirer))
        case .unknown:
            return Single.error(CardAcquirerError.unknownAcquirer)
        }
    }

    /// Add via every pay
    private func add(
        card: CardData,
        with everyPayData: ActivateCardResponse.Partner.EveryPayData
    ) -> Single<PartnerAuthorizationData.State> {
        everyPayClient
            .send(
                cardDetails: card.everyPayCardDetails,
                apiUserName: everyPayData.apiUsername,
                token: everyPayData.mobileToken
            )
            .map { response -> PartnerAuthorizationData.State in
                switch response.status {
                case .waitingFor3DResponse:
                    let url = URL(string: everyPayData.paymentLink)!
                    return .required(.init(cardAcquirer: .everyPay, paymentLink: url))
                case .failed, .authorized, .settled, .waitingForBav:
                    return .none
                }
            }
            .asSingle()
            .do(onError: { [weak self] error in
                self?.analyticsRecorder.record(
                    event: CardUpdateEvent.sbCardEverypayFailure(data: String(describing: error))
                )
            })
    }
}
