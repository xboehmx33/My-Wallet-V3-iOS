// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import FeatureSettingsDomain
import MoneyKit
import PlatformKit
import PlatformUIKit
import RxCocoa
import RxRelay
import RxSwift

final class AddPaymentMethodInteractor {

    enum PaymentMethod {
        case card
        case bank(FiatCurrency)

        var fiatCurrency: FiatCurrency? {
            guard case .bank(let currency) = self else { return nil }
            return currency
        }
    }

    /// Do all the checks and streams `true` if the user is able to add a new bank / card / whatever payment method
    let isEnabledForUser: Observable<Bool>

    let isAbleToAddNew: Observable<Bool>

    let isKYCVerified: Observable<Bool>

    let paymentMethod: PaymentMethod
    private let addNewInteractor: AddSpecificPaymentMethodInteractorAPI
    private let tiersLimitsProvider: TierLimitsProviding

    init(
        paymentMethod: PaymentMethod,
        addNewInteractor: AddSpecificPaymentMethodInteractorAPI,
        tiersLimitsProvider: TierLimitsProviding
    ) {
        self.paymentMethod = paymentMethod
        self.addNewInteractor = addNewInteractor
        self.tiersLimitsProvider = tiersLimitsProvider

        isAbleToAddNew = addNewInteractor.isAbleToAddNew
            .catchErrorJustReturn(false)
            .share(replay: 1)

        isKYCVerified = tiersLimitsProvider.tiers
            .map(\.isTier2Approved)
            .catchErrorJustReturn(false)
            .share(replay: 1)

        isEnabledForUser = Observable.combineLatest(isAbleToAddNew, isKYCVerified)
            .map { $0.0 && $0.1 }
            .share(replay: 1)
    }
}
