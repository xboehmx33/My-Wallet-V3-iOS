// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
import PlatformKit
import RxRelay
import RxSwift
import ToolKit

/// A passive state receiver API for Simple-Buy flow.
public protocol StateReceiverServiceAPI: AnyObject {

    /// The action that should be executed, the `next` action
    /// is coupled with the current state
    var action: Observable<StateService.Action> { get }
}

/// A checkout service API
public protocol CheckoutServiceAPI: RoutingPreviousStateEmitterAPI {
    var previousRelay: PublishRelay<Void> { get }

    func nextFromBuyCrypto(with checkoutData: CheckoutData)
    func nextFromCardLinkSelection()
    func nextFromBankLinkSelection()
    func ineligible(with checkoutData: CheckoutData)
    func ineligible()
    func kyc(with checkoutData: CheckoutData)
    func cardRoutingInteractor(with checkoutData: CheckoutData?) -> CardRouterInteractor
    func paymentMethods()
    func changeCurrency()
    func currencySelected()
    func reselectCurrency()
    func promptTierUpgrade()
}

public protocol PaymentMethodsStateAPI: RoutingPreviousStateEmitterAPI {
    func showFundsTransferDetails(for fiatCurrency: FiatCurrency, isOriginDeposit: Bool)
    func kyc()
}

public protocol ElibilityRelayAPI: RoutingPreviousStateEmitterAPI {
    func ineligible(with currency: FiatCurrency)
}

/// A confirm-checkout service API
public protocol TransferDetailsServiceAPI: RoutingPreviousStateEmitterAPI {
    func bankTransferDetails(with checkoutData: CheckoutData)
}

/// A confirm-checkout service API
public protocol ConfirmCheckoutServiceAPI: RoutingPreviousStateEmitterAPI {
    /// - parameter isOrderNew: Bool flag representing if the given `CheckoutData` is from a newly created order
    /// or if it is from an existing order.
    func confirmCheckout(with checkoutData: CheckoutData, isOrderNew: Bool)
}

/// A cancellation service API
public protocol CancelTransferServiceAPI: RoutingPreviousStateEmitterAPI {
    func cancelTransfer(with checkoutData: CheckoutData)
}

public protocol CurrencySelectionServiceAPI {
    func currencySelected()
    func reselectCurrency()
}

public protocol StateCacheProviderAPI: AnyObject {
    var cache: Atomic<EventCache> { get }
}

public protocol PendingOrderCompletionStateServiceAPI: AnyObject {
    func orderPending(with orderDetails: OrderDetails)
    func orderCompleted()
}

public protocol URLSelectionServiceAPI: AnyObject {
    func show(url: URL)
}

public protocol AuthorizedOpenBankingAPI: RoutingPreviousStateEmitterAPI {
    func authorizedOpenBanking()
}

/// A composition of all of Simple-Buy state-services
public typealias StateServiceAPI = RoutingStateEmitterAPI &
    StateReceiverServiceAPI &
    TransferDetailsServiceAPI &
    ConfirmCheckoutServiceAPI &
    StateCacheProviderAPI &
    CheckoutServiceAPI &
    CancelTransferServiceAPI &
    CurrencySelectionServiceAPI &
    CardAuthorizationRoutingInteractorAPI &
    PendingOrderCompletionStateServiceAPI &
    ElibilityRelayAPI &
    URLSelectionServiceAPI &
    PaymentMethodsStateAPI &
    AuthorizedOpenBankingAPI
