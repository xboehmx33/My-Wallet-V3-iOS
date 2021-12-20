// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import ComposableArchitecture
import DIKit
import FeatureTransactionDomain
import MoneyKit
import PlatformKit
import PlatformUIKit
import SwiftUI
import ToolKit
import UIKit

public protocol KYCSDDServiceAPI {

    func checkSimplifiedDueDiligenceEligibility() -> AnyPublisher<Bool, Never>
    func checkSimplifiedDueDiligenceVerification() -> AnyPublisher<Bool, Never>
}

protocol LegacyBuyFlowRouting {

    func presentBuyFlowWithTargetCurrencySelectionIfNecessary(
        from presenter: UIViewController
    ) -> AnyPublisher<TransactionFlowResult, Never>

    func presentBuyScreen(
        from presenter: UIViewController,
        targetCurrency: CryptoCurrency,
        isSDDEligible: Bool
    ) -> AnyPublisher<TransactionFlowResult, Never>
}

class LegacyBuyFlowRouter: LegacyBuyFlowRouting {

    private enum CrytoSelectionResult {
        case abandoned
        case select(CryptoCurrency)
    }

    private let cryptoCurrenciesService: CryptoCurrenciesServiceAPI
    private let walletFiatCurrencyService: FiatCurrencyServiceAPI
    private let kycService: KYCSDDServiceAPI

    private var buyRouter: PlatformUIKit.Router! // reference stored otherwise the app crashes for some reason 😕

    init(
        cryptoCurrenciesService: CryptoCurrenciesServiceAPI = resolve(),
        walletFiatCurrencyService: FiatCurrencyServiceAPI = resolve(),
        kycService: KYCSDDServiceAPI = resolve()
    ) {
        self.cryptoCurrenciesService = cryptoCurrenciesService
        self.walletFiatCurrencyService = walletFiatCurrencyService
        self.kycService = kycService
    }

    func presentBuyScreen(
        from presenter: UIViewController,
        targetCurrency: CryptoCurrency,
        isSDDEligible: Bool
    ) -> AnyPublisher<TransactionFlowResult, Never> {
        // This is just levereging the existing buy flow, which isn't great but is getting replaced buy the new `Transactions` implementation
        let presentBuy = {
            let builder = PlatformUIKit.Builder(
                stateService: PlatformUIKit.StateService()
            )
            self.buyRouter = PlatformUIKit.Router(builder: builder, currency: targetCurrency)
            self.buyRouter.start(skipIntro: isSDDEligible)
        }

        // The current buy flow implementation is too complex to modify to get a callback
        // so, for now, dimiss any previously presented and present the buy flow. Then return an empty publisher.
        if presenter.presentedViewController != nil {
            presenter.dismiss(animated: true, completion: presentBuy)
        } else {
            presentBuy()
        }
        return Empty(completeImmediately: true)
            .eraseToAnyPublisher()
    }

    func presentBuyFlowWithTargetCurrencySelectionIfNecessary(
        from presenter: UIViewController
    ) -> AnyPublisher<TransactionFlowResult, Never> {
        // Step 1. check SDD eligibility to understand which flow to show next
        kycService.checkSimplifiedDueDiligenceEligibility()
            .zip(walletFiatCurrencyService.displayCurrencyPublisher)
            .receive(on: DispatchQueue.main)
            .flatMap { [weak self] userIsSDDEligible, fiatCurrency -> AnyPublisher<TransactionFlowResult, Never> in
                guard let self = self else {
                    unexpectedDeallocation()
                }
                guard userIsSDDEligible else {
                    // Step 2 (non-SDD eligible). Step Present present simple buy flow
                    // This is just levereging the existing buy flow, which isn't great but is getting replaced buy the new `Transactions` implementation
                    return self.presentBuyScreen(
                        from: presenter,
                        targetCurrency: .coin(.bitcoin), // not important for simple buy
                        isSDDEligible: false
                    )
                }
                // Step 2a. present currency selection screen
                return self.presentCryptoCurrencySelectionScreen(from: presenter, fiatCurrency: fiatCurrency)
                    .flatMap { [weak self] result -> AnyPublisher<TransactionFlowResult, Never> in
                        guard let self = self else {
                            unexpectedDeallocation()
                        }
                        // Step 2b. present buy flow screen for selected crypto and locale's fiat currency
                        guard case .select(let cryptoCurrency) = result else {
                            return .just(.abandoned)
                        }
                        return self.presentBuyScreen(
                            from: presenter,
                            targetCurrency: cryptoCurrency,
                            isSDDEligible: userIsSDDEligible
                        )
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Helpers

    private func presentCryptoCurrencySelectionScreen(
        from presenter: UIViewController,
        fiatCurrency: FiatCurrency
    ) -> AnyPublisher<CrytoSelectionResult, Never> {
        let publisher = PassthroughSubject<CrytoSelectionResult, Never>()
        presenter.present(
            NavigationView {
                CryptoCurrencySelectionView(
                    store: Store(
                        initialState: CryptoCurrencySelectionState(),
                        reducer: cryptoCurrencySelectionReducer,
                        environment: CryptoCurrencySelectionEnvironment(
                            mainQueue: .main,
                            close: {
                                publisher.send(.abandoned)
                                publisher.send(completion: .finished)
                            },
                            select: { selectedCryptoCurrency in
                                publisher.send(.select(selectedCryptoCurrency))
                            },
                            loadCryptoCurrencies: { [cryptoCurrenciesService] in
                                cryptoCurrenciesService.fetchPurchasableCryptoCurrencies(using: fiatCurrency)
                            }
                        )
                    )
                )
                .whiteNavigationBarStyle()
            }
            .navigationViewStyle(StackNavigationViewStyle())
        )
        return publisher.eraseToAnyPublisher()
    }
}
