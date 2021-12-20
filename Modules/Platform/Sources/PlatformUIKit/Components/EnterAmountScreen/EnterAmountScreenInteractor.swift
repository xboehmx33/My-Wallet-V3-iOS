// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
import PlatformKit
import RIBs
import RxSwift
import ToolKit

/// API for interaction of enter amount screen
public protocol EnterAmountScreenInteractorAPI: AnyObject {
    var hasValidState: Observable<Bool> { get }
    var selectedCurrencyType: Observable<CurrencyType> { get }

    func didLoad()
}

open class EnterAmountScreenInteractor: Interactor, EnterAmountScreenInteractorAPI {

    /// Must be implemented - decides whether the interactor has a valid state.
    /// if streams `true`, then the CTA button would become enabled.
    /// `super.hasValidState` must not be called by the subclass.
    open var hasValidState: Observable<Bool> {
        unimplemented()
    }

    /// Must be implemented - selected currency
    /// `super.selectedCryptoCurrency` must not be called by the subclass.
    open var selectedCurrencyType: Observable<CurrencyType> {
        unimplemented()
    }

    /// Any one time initialization performed when the bound view controller appears.
    /// `super.didLoad` must not be called by the subclass.
    open func didLoad() {
        unimplemented()
    }

    // MARK: - Injected

    public let priceService: PriceServiceAPI
    public let fiatCurrencyService: FiatCurrencyServiceAPI
    public let cryptoCurrencySelectionService: SelectionServiceAPI & CryptoCurrencyServiceAPI

    // MARK: - Interactors

    /// Amount translation interactor
    public let amountTranslationInteractor: AmountTranslationInteractor

    public init(
        priceService: PriceServiceAPI,
        fiatCurrencyService: FiatCurrencyServiceAPI,
        cryptoCurrencySelectionService: SelectionServiceAPI & CryptoCurrencyServiceAPI,
        initialActiveInput: ActiveAmountInput
    ) {
        self.priceService = priceService
        self.fiatCurrencyService = fiatCurrencyService
        self.cryptoCurrencySelectionService = cryptoCurrencySelectionService

        amountTranslationInteractor = AmountTranslationInteractor(
            fiatCurrencyClosure: {
                fiatCurrencyService.displayCurrency.asObservable()
            },
            cryptoCurrencyService: cryptoCurrencySelectionService,
            priceProvider: AmountTranslationPriceProvider(),
            defaultCryptoCurrency: .coin(.bitcoin),
            initialActiveInput: initialActiveInput
        )
    }
}
