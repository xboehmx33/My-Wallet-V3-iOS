// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
import RxSwift

/// Types adopting the `PaymentMethodsServiceAPI` protocol should provide a way to fetch the eligible payment methods for the current user.
public protocol PaymentMethodsServiceAPI: AnyObject {

    func supportedPaymentMethods(for currency: FiatCurrency) -> Single<[PaymentMethod]>

    /// Streams the available eligible payment methods for the user
    var paymentMethods: Observable<[PaymentMethod]> { get }
    /// Returns the available eligible payment methods for the user
    var paymentMethodsSingle: Single<[PaymentMethod]> { get }
    /// Returns the available card types that the user can add
    var supportedCardTypes: Single<Set<CardType>> { get }
    /// Refreshes the stream of `paymentMethods`
    func refresh()
}
