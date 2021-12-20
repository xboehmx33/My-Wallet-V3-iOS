// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComposableArchitecture
import DIKit
@testable import FeatureTourUI
import MoneyKit
import PlatformKit
import SnapshotTesting
import XCTest

class TourViewTests: XCTestCase {

    override func setUp() {
        super.setUp()
        DependencyContainer.defined(by: modules {
            DependencyContainer.mockDependencyContainer
        })
    }

    func testTourView() {
        let view = TourView(
            environment: TourEnvironment(
                createAccountAction: {},
                restoreAction: {},
                logInAction: {}
            )
        )
        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone8)))

        let brokerageView = TourView.Carousel.brokerage.makeView()
        assertSnapshot(matching: brokerageView, as: .image(layout: .device(config: .iPhone8)))

        let earnView = TourView.Carousel.earn.makeView()
        assertSnapshot(matching: earnView, as: .image(layout: .device(config: .iPhone8)))

        let keysView = TourView.Carousel.keys.makeView()
        assertSnapshot(matching: keysView, as: .image(layout: .device(config: .iPhone8)))

        let items = [
            Price(currency: .coin(.bitcoin), value: .loaded(next: "$55,343.76"), deltaPercentage: .loaded(next: 7.88)),
            Price(currency: .coin(.ethereum), value: .loaded(next: "$3,585.69"), deltaPercentage: .loaded(next: 1.82)),
            Price(currency: .coin(.bitcoinCash), value: .loaded(next: "$618.05"), deltaPercentage: .loaded(next: -3.46)),
            Price(currency: .coin(.stellar), value: .loaded(next: "$0.36"), deltaPercentage: .loaded(next: 12.50))
        ]
        var tourState = TourState()
        tourState.items = IdentifiedArray(uniqueElements: items)
        let mockTourReducer: Reducer<TourState, TourAction, TourEnvironment> = Reducer { _, _, _ in
            .none
        }
        let tourStore = Store(
            initialState: tourState,
            reducer: mockTourReducer,
            environment: TourEnvironment(createAccountAction: {}, restoreAction: {}, logInAction: {})
        )
        let livePricesView = LivePricesView(
            store: tourStore,
            list: LivePricesList(store: tourStore)
        )
        assertSnapshot(matching: livePricesView, as: .image(layout: .device(config: .iPhone8)))
    }
}

/// This is needed in order to resolve the dependencies
struct MockEnabledCurrenciesServiceAPI: EnabledCurrenciesServiceAPI {
    var allEnabledCurrencies: [CurrencyType] { [] }
    var allEnabledCryptoCurrencies: [CryptoCurrency] { [] }
    var allEnabledFiatCurrencies: [FiatCurrency] { [] }
    var bankTransferEligibleFiatCurrencies: [FiatCurrency] { [] }
}

extension DependencyContainer {

    static var mockDependencyContainer = module {
        factory { MockEnabledCurrenciesServiceAPI() as EnabledCurrenciesServiceAPI }
    }
}
