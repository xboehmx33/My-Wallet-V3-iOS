// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import MoneyKit
import PlatformKit
import RIBs
import RxSwift

final class PendingOrderStateScreenInteractor: Interactor {

    // MARK: - Properties

    var amount: MoneyValue {
        isBuy ? orderDetails.outputValue : orderDetails.inputValue
    }

    var isBuy: Bool {
        orderDetails.isBuy
    }

    var inputCurrencyType: CurrencyType {
        orderDetails.inputValue.currency
    }

    var outputCurrencyType: CurrencyType {
        orderDetails.outputValue.currency
    }

    private let orderDetails: OrderDetails
    private let service: PendingOrderCompletionServiceAPI
    private let tiersService: KYCTiersServiceAPI

    // MARK: - Setup

    init(
        orderDetails: OrderDetails,
        service: PendingOrderCompletionServiceAPI = resolve(),
        tiersService: KYCTiersServiceAPI = resolve()
    ) {
        self.orderDetails = orderDetails
        self.service = service
        self.tiersService = tiersService
    }

    func startPolling() -> Single<PolledOrder> {
        service.waitForFinalizedState(of: orderDetails.identifier)
    }

    func fetchTierUpgradeEligility() -> Single<Bool> {
        guard isBuy else {
            return .just(false)
        }
        return tiersService.fetchTiers()
            .asSingle()
            .map { $0.latestApprovedTier < .tier2 }
    }
}
